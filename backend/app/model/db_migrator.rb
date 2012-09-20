require 'sequel'
require 'sequel/adapters/shared/mysql'

Sequel::MySQL.default_engine = 'InnoDB'
Sequel::MySQL.default_charset = 'utf8'


Sequel.extension :migration


module Sequel
  module Schema
    class CreateTableGenerator
      def TextField(field, opts = {})
        if $db_type == :derby
          String field, opts.merge(:size => 2048)
        else
          Text field, opts
        end
      end
    end
  end
end


class DBMigrator

  MIGRATIONS_DIR = File.join(File.dirname(__FILE__), "migrations")


  def self.setup_database(db)
    $db_type = db.database_type
    Sequel::Migrator.run(db, MIGRATIONS_DIR)
  end


  def self.nuke_database(db)
    $db_type = db.database_type
    Sequel::Migrator.run(db, MIGRATIONS_DIR, :target => 0)
  end

  def self.needs_updating?(db)
    $db_type = db.database_type
    not Sequel::Migrator.is_current?(db, MIGRATIONS_DIR)
  end

end
