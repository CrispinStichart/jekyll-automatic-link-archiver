#!/usr/bin/env/ ruby
# frozen_string_literal: true

require 'jekyll'
require 'nokogiri'
require 'date'
require 'uri'

require 'link-archiver/database'

module Jekyll::Archive
  # Test Comment to make linter shut up
  class ArchiveLink
    # NOTE: must have trailing slash
    ARCHIVES_DIR = 'archives/'

    def initialize
      @db = Jekyll::Archive::Database.new
      # TODO: read from config
      @inline_link = true
    end

    def archive(doc)
      html = Nokogiri::HTML(doc.output)
      html.css('.post a').each do |node|
        href = node['href']
        next unless offsite_link?(href)

        archived_location = archive_or_get_from_db(href)
        insert_archive_link(node, archived_location, html) if @inline_link
      end
      doc.output = html.to_s
    end

    def archive_or_get_from_db(url)
      archived_location = @db.get_archive_dir(url)
      unless archived_location
        archived_location = download_page(url)
        @db.add_archive(url, archived_location, Time.now.iso8601)
      end
      archived_location
    end

    def insert_archive_link(node, archived_location, dom)
      archive_link = Nokogiri::XML::Node.new('a', dom)
      archive_link.content = 'archive'
      archive_link['class'] = 'archive-link'
      archive_link['href'] = archived_location

      node.add_next_sibling(archive_link)
      # puts("TEST: #{archive_link}")
    end

    # @param url [String]
    def download_page(url)
      # The only invalid character for Unix filenames is a forward slash.
      # Windows is more restrictive but I don't care enough right now to do
      # more than the bare minimum.
      download_dir = ARCHIVES_DIR + url.gsub('/', '_').gsub('\\', '_')
      `wget -p --convert-links -nH -nd -P#{download_dir} --user-agent="Mozilla" #{url}`
      location = "#{download_dir}/#{self.class.get_page_filename(url)}"
      # If any parts of the page fail to dowload, the exit code will be non-zero.
      # This doesn't necessarily mean that the entire page failed. If something went
      # super wrong, however, the download dir won't ever be created.
      return location if File.directory?(download_dir) == true

      puts "Failed to download the page at #{url}"
      nil
    end

    # @param link [String]
    # @return [Boolean]
    def offsite_link?(link)
      link.start_with?('http')
    end

    # extracts the filename, or nothing if it's a directory
    def self.get_page_filename(url)
      path = URI(url).path
      first_slash = path.rindex('/')
      return '' unless first_slash

      path[first_slash + 1..]
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
  Jekyll::Archive::ArchiveLink.new.archive(doc) if Jekyll::Archive::ArchiveLink.html?(doc)
end
