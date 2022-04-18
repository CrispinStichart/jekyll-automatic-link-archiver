# frozen_string_literal: true

require 'sqlite3'

# module Jekyll
# end

module Jekyll::Archive
  class Database
    def initialize
      @db = SQLite3::Database.new 'archives.db'
      @db.transaction do |db|
        db.execute('CREATE TABLE IF NOT EXISTS archives '\
                   '(url TEXT PRIMARY KEY, location TEXT, date TEXT )')
      end
    end

    def get_archive_dir(url)
      @db.get_first_value('SELECT location FROM archives WHERE url=?', url)
    end

    def add_archive(url, location, date)
      @db.transaction do |db|
        db.execute('INSERT INTO archives VALUES (?, ?, ?)', url, location, date)
      end
    end
  end
end
