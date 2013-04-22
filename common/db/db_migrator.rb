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
          Clob field, opts
        else
          Text field, opts
        end
      end


      def LongString(field, opts = {})
        String field, opts.merge(:size => 17408)
      end


      def TextBlobField(field, opts = {})
        if $db_type == :derby
          Clob field, opts
        else
          BlobField(field, opts)
        end
      end


      def BlobField(field, opts = {})
        if $db_type == :postgres
          Bytea field, opts
        elsif $db_type == :h2
          String field, opts.merge(:size => 128000)
        else
          Blob field, opts
        end
      end


      def DynamicEnum(field, opts = {})
        Integer field, opts
        foreign_key([field], :enumeration_value, :key => :id)
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
