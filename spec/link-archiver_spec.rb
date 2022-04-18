require 'spec_helper'
require 'fileutils'

ARCHIVE_DATABASE = 'archives.db'
File.delete(ARCHIVE_DATABASE) if File.exist?(ARCHIVE_DATABASE)

ARCHIVES_DIR = 'archives/'
FileUtils.remove_dir(ARCHIVES_DIR, force = true)

class Document
  attr_accessor :output

  def initialize
    @output = File.read(File.expand_path('fixture/test.html', __dir__))
  end
end

RSpec.describe(Jekyll::Archive::Database) do
  it 'gets nil for a non-archived URL' do
    db = Jekyll::Archive::Database.new
    archive_dir = db.get_archive_dir('google.com')
    expect(archive_dir).to eq(nil)
  end

  it 'inputs data without error' do
    db = Jekyll::Archive::Database.new
    db.add_archive('google.com', 'archives/google.com/', 'today')
  end

  it 'retrieves data correctly' do
    db = Jekyll::Archive::Database.new
    archive_dir = db.get_archive_dir('google.com')
    expect(archive_dir).to eq('archives/google.com/')
  end
end

RSpec.describe(Jekyll::Archive::ArchiveLink) do
  it 'extracts filenames from URLs' do
    filename = Jekyll::Archive::ArchiveLink.get_page_filename('https://google.com')
    expect(filename).to eq('')

    filename = Jekyll::Archive::ArchiveLink.get_page_filename('https://google.com/')
    expect(filename).to eq('')

    filename = Jekyll::Archive::ArchiveLink.get_page_filename('https://google.com/test/posts/')
    expect(filename).to eq('')

    filename = Jekyll::Archive::ArchiveLink.get_page_filename('https://google.com/test.html')
    expect(filename).to eq('test.html')
  end

  it 'downloads valid page' do
    archiver = Jekyll::Archive::ArchiveLink.new
    archived_location = archiver.download_page('https://crispinstichart.github.io/i-hate-elden-ring/')
    expect(archived_location).not_to eq(nil)
  end

  it 'return nil when not downloading anything' do
    archiver = Jekyll::Archive::ArchiveLink.new
    archived_location = archiver.download_page('https://www.blah-whatever-not-a-real-website.xxx')
    expect(archived_location).to eq(nil)
  end

  # TODO: expect something (for now I'm just manually inspecting the output)
  it 'all just works' do
    archiver = Jekyll::Archive::ArchiveLink.new
    doc = Document.new
    archiver.archive(doc)
    puts doc.output
  end
end
