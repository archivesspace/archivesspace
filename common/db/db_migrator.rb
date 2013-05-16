require 'sequel'
require 'sequel/adapters/shared/mysql'
require 'config/config-distribution'

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
      
      def HalfLongString(field, opts = {})
        String field, opts.merge(:size => 8704)
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
  PLUGIN_MIGRATIONS = []
  PLUGIN_MIGRATION_DIRS = {}
  AppConfig[:plugins].each do |plugin|
    mig_dir = File.join(File.dirname(__FILE__), "..", "..",
                        "plugins", plugin, "migrations")
    if Dir.exists?(mig_dir)
      PLUGIN_MIGRATIONS << plugin
      PLUGIN_MIGRATION_DIRS[plugin] = mig_dir
    end
  end

  def self.setup_database(db)
    $db_type = db.database_type
    Sequel::Migrator.run(db, MIGRATIONS_DIR)
    PLUGIN_MIGRATIONS.each { |plugin| Sequel::Migrator.run(db, PLUGIN_MIGRATION_DIRS[plugin],
                                                           :table => "#{plugin}_schema_info") }
  end


  def self.nuke_database(db)
    $db_type = db.database_type
    PLUGIN_MIGRATIONS.reverse.each { |plugin| Sequel::Migrator.run(db, PLUGIN_MIGRATION_DIRS[plugin],
                                                                     :table => "#{plugin}_schema_info", :target => 0) }
    Sequel::Migrator.run(db, MIGRATIONS_DIR, :target => 0)
  end

  def self.needs_updating?(db)
    $db_type = db.database_type
    return true unless Sequel::Migrator.is_current?(db, MIGRATIONS_DIR)
    PLUGIN_MIGRATIONS.each { |plugin| return true unless Sequel::Migrator.is_current?(db, PLUGIN_MIGRATIONS_DIR[plugin],
                                                                                      :table => "#{plugin}_schema_info") }
  end

end
