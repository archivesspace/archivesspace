require 'sequel'
require 'sequel/adapters/shared/mysql'

Sequel::MySQL.default_engine = 'InnoDB'
Sequel::MySQL.default_charset = 'utf8'


Sequel.extension :migration

class DBMigrator

  MIGRATIONS_DIR = File.join(File.dirname(__FILE__), "migrations")


  def self.setup_database(db)
    Sequel::Migrator.run(db, MIGRATIONS_DIR)
  end


  def self.nuke_database(db)
    Sequel::Migrator.run(db, MIGRATIONS_DIR, :target => 0)
  end

  def self.needs_updating?(db)
    not Sequel::Migrator.is_current?(db, MIGRATIONS_DIR)
  end

end
