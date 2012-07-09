require 'sequel'
require 'sequel/adapters/shared/mysql'

Sequel::MySQL.default_engine = 'InnoDB'
Sequel::MySQL.default_charset = 'utf8'


Sequel.extension :migration

class DBMigrator

  def self.setup_database(db)
    migrations_dir = File.join(File.dirname(__FILE__), "migrations")

    Sequel::Migrator.run(db, migrations_dir)
  end

end
