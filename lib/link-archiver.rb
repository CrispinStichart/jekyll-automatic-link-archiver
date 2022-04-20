#!/usr/bin/env/ ruby
# frozen_string_literal: true

require 'jekyll'
require 'nokogiri'
require 'date'
require 'uri'

module Jekyll::Archive
  # Test Comment to make linter shut up
  class ArchiveLink
    def initialize(doc)
      # TODO: read from config
      @doc = doc
      @config = doc.site.config[:link_archiver]
      @archive_url = @config[:archive_url]
      @archive_dir = @config[:archive_dir]
      @inline_link = @config[:inline_link]
      @exclude_list = @config[:exclude]
    end

    def archive
      # use doc.site.config to get the config options, which is in hash form.
      html = Nokogiri::HTML(@doc.output)
      html.css('.post a').each do |node|
        href = node['href']
        next unless offsite_link?(href)

        archived_location = archive_url_or_get_from_cache(href)
        insert_archive_link(node, archived_location, html) if @inline_link
      end
      @doc.output = html.to_s
    end

    def archive_url_or_get_from_cache(url)
      archived_location = @archive_dir + sanitize_url(url)
      # TODO: refactor this
      archived_location = URI.decode_www_form_component(archived_location)
      archived_location = download_page(url) unless File.directory? archived_location
      archived_location
    end

    def insert_archive_link(node, archived_location, dom)
      archive_link = Nokogiri::XML::Node.new('a', dom)
      archive_link.content = 'archive'
      archive_link['class'] = 'archive-link'
      archive_link['href'] = "#{@archive_url}/#{archived_location}"

      node.add_next_sibling(archive_link)
      # puts("TEST: #{archive_link}")
    end

    # @param url [String]
    def download_page(url)
      download_dir = @archive_dir + sanitize_url(url) + '/'
      # We're decoding here because jekyll seems to be auto decoding when it
      # moves files into _site/.
      download_dir = URI.decode_www_form_component(download_dir)
      `wget -p --convert-links -nH -nd -P#{download_dir} --user-agent="Mozilla" #{url}`

      # If any parts of the page fail to dowload, the exit code will be non-zero.
      # This doesn't necessarily mean that the entire page failed. If something went
      # super wrong, however, the download dir won't ever be created.
      if File.directory?(download_dir) == false
        puts "Failed to download the page at #{url}"
        return nil
      end

      # If it was a specific page we downloaded and not a directory, than we
      # rename it to "index.html". We do this so we can build a generator plugin
      # that inserts an archive... page... just realized that there may be some
      # problems... OH WELL CARRY ON

      page_filename = get_page_filename(url)
      location = "#{download_dir}/#{page_filename}"
      File.rename(location, "#{download_dir}/index.html") if page_filename != ''

      download_dir
    end

    # @param link [String]
    # @return [Boolean]
    def offsite_link?(link)
      link.start_with?('http')
    end

    def sanitize_url(url)
      # The only invalid character for Unix filenames is a forward slash.
      # Windows is more restrictive but I don't care enough right now to do
      # more than the bare minimum.
      url.gsub('/', '_').gsub('\\', '_')
    end

    # extracts the filename, or nothing if it's a directory
    def get_page_filename(url)
      uri = URI(url)
      path = uri.path
      first_slash = path.rindex('/')
      return '' unless first_slash

      # Wget saves the file with the query in the name
      location = path[first_slash + 1..]
      location = location + '?' + uri.query if uri.query
      # Wget also unescapes filenames
      URI.decode_www_form_component(location)
    end

    def self.html?(doc)
      # TODO: look up .write, figure out what this is actually checking
      #       for. Should the ORs be together?
      ((doc.is_a?(Jekyll::Page) || doc.write?) &&
        doc.output_ext == '.html') || doc.permalink&.end_with?('/')
    end
  end
end

Jekyll::Hooks.register [:posts], :post_render do |doc|
  Jekyll::Archive::ArchiveLink.new(doc).archive if Jekyll::Archive::ArchiveLink.html?(doc)
end
