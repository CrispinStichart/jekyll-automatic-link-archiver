#!/usr/bin/env/ ruby
# frozen_string_literal: true

require 'jekyll'
require 'nokogiri'
require 'date'

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

        archived_location = @db.get_archive_dir(href)
        if archived_location
          insert_archive_link(node, archived_location) if @inline_link
        else
          url, download_dir = download_page(href)
          @db.set_archive_dir(url, download_dir, Time.now.iso8601)
        end
      end
      doc.output = html.to_s
    end

    def insert_archive_link(node, archived_location)
      archive_link = Nokogiri::XML::Node.new('a', html)
      archive_link.content = 'archive'
      archive_link['class'] = 'archive-link'
      archive_link['href'] = archived_location

      node.add_next_sibling(archive_link)
      # puts("TEST: #{archive_link}")
    end

    # @param url [String]
    def download_page(url)
      download_dir = ARCHIVES_DIR + url.gsub('\\', '_')

      output = `wget -p --convert-links -nH -nd -P#{download_dir} #{url}`
      return url, download_dir if $?.exitstatus.zero?

      puts "Failed to download the page at #{url}"
      puts output
      nil
    end

    # @param link [String]
    # @return [Boolean]
    def offsite_link?(link)
      link.start_with?('http')
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
