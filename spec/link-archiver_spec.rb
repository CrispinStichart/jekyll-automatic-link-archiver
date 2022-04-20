require 'spec_helper'
require 'fileutils'

ARCHIVES_DIR = 'archives/'
FileUtils.remove_dir(ARCHIVES_DIR, force = true)

class Site
  attr_accessor :config

  def initialize
    @config = { link_archiver: { archive_url: 'http://127.0.0.1:4000/',
                                 archive_dir: 'archives/',
                                 inline_link: true,
                                 exclude: ['.*youtube\\..*'] } }
  end
end

class Document
  attr_accessor :output, :site

  def initialize
    @output = File.read(File.expand_path('fixture/test.html', __dir__))
    @site = Site.new
  end
end

DOC = Document.new

RSpec.describe(Jekyll::Archive::ArchiveLink) do
  it 'extracts filenames from URLs' do
    archiver = Jekyll::Archive::ArchiveLink.new(DOC)
    filename = archiver.get_page_filename('https://google.com')
    expect(filename).to eq('')

    filename = archiver.get_page_filename('https://google.com/')
    expect(filename).to eq('')

    filename = archiver.get_page_filename('https://google.com/test/posts/')
    expect(filename).to eq('')

    filename = archiver.get_page_filename('https://google.com/test.html')
    expect(filename).to eq('test.html')
  end

  it 'downloads valid page' do
    archiver = Jekyll::Archive::ArchiveLink.new(DOC)
    archived_location = archiver.download_page('https://crispinstichart.github.io/i-hate-elden-ring/')
    expect(archived_location).not_to eq(nil)
  end

  it 'return nil when not downloading anything' do
    archiver = Jekyll::Archive::ArchiveLink.new(DOC)
    archived_location = archiver.download_page('https://www.blah-whatever-not-a-real-website.xxx')
    expect(archived_location).to eq(nil)
  end

  # TODO: expect something (for now I'm just manually inspecting the output)
  it 'all just works' do
    archiver = Jekyll::Archive::ArchiveLink.new(DOC)
    archiver.archive
    puts DOC.output
  end
end
