require 'sequel'
require 'sequel/adapters/shared/mysql'
require 'config/config-distribution'
require 'asutils'

Sequel.database_timezone = :utc
Sequel.typecast_timezone = :utc

Sequel.extension :migration
Sequel.extension :core_extensions
Sequel.split_symbols = true

module ColumnDefs

  def self.textField(name, opts = {})
    if $db_type == :derby
      [name, :clob, opts]
    else
      [name, :text, opts]
    end
  end


  def self.longString(name, opts = {})
    [name, String, opts.merge(:size => 17408)]
  end

  def self.halfLongString(name, opts = {})
    [name, String, opts.merge(:size => 8704)]
  end


  def self.textBlobField(name, opts = {})
    if $db_type == :derby
      [name, :clob, opts]
    else
      self.blobField(name, opts)
    end
  end


  def self.blobField(name, opts = {})
    if $db_type == :postgres
      [name, :bytea, opts]
    elsif $db_type == :h2
      [name, String, opts.merge(:size => 128000)]
    else
      [name, :blob, opts]
    end
  end


  def self.mediumBlobField(name, opts = {})
    if $db_type == :postgres
      [name, :bytea, opts]
    elsif $db_type == :h2
      [name, String, opts.merge(:size => 128000)]
    elsif $db_type == :mysql
      [name, :mediumblob, opts]
    else
      [name, :blob, opts]
    end
  end

end


# Sequel uses a nice DSL for creating tables but not for altering tables.  The
# definitions below try to provide a reasonable experience for both cases.
# Creation is the normal:
#
#   HalfLongString :title, :null => true
#
# while altering is (to add a column):
#
#   HalfLongString :title
#

module SequelColumnTypes

  def create_column(*column_def)
    if self.respond_to?(:column)
      column(*column_def)
    else
      add_column(*column_def)
    end
  end


  def TextField(field, opts = {})
    create_column(*ColumnDefs.textField(field, opts))
  end


  def LongString(field, opts = {})
    create_column(*ColumnDefs.longString(field, opts))
  end

  def HalfLongString(field, opts = {})
    create_column(*ColumnDefs.halfLongString(field, opts))
  end


  def TextBlobField(field, opts = {})
    create_column(*ColumnDefs.textBlobField(field, opts))
  end


  def BlobField(field, opts = {})
    create_column(*ColumnDefs.blobField(field, opts))
  end


  def MediumBlobField(field, opts = {})
    create_column(*ColumnDefs.mediumBlobField(field, opts))
  end


  def DynamicEnum(field, opts = {})
    Integer field, opts
    foreign_key([field], :enumeration_value, :key => :id)
  end


  def apply_name_columns
    String :authority_id, :null => true
    String :dates, :null => true
    TextField :qualifier, :null => true
    DynamicEnum :source_id, :null => true
    DynamicEnum :rules_id, :null => true
    TextField :sort_name, :null => false
    Integer :sort_name_auto_generate
  end

  def apply_parallel_name_columns
    String :dates, :null => true
    TextField :qualifier, :null => true
    DynamicEnum :source_id, :null => true
    DynamicEnum :rules_id, :null => true
    TextField :sort_name, :null => false
    Integer :sort_name_auto_generate, :default => 1
  end

  def apply_mtime_columns(create_time = true)
    String :created_by
    String :last_modified_by

    if create_time
      DateTime :create_time, :null => false
    end

    DateTime :system_mtime, :null => false, :index => true
    DateTime :user_mtime, :null => false, :index => true
  end

end


module Sequel

  module Schema
    class CreateTableGenerator
      include SequelColumnTypes
    end

    class AlterTableGenerator
      include SequelColumnTypes
    end
  end

end


class DBMigrator

  def self.order_plugins(plugins)
    ordered_plugin_dirs = ASUtils.order_plugins(plugins.map {|p| File.join(ASUtils.plugin_base_directory, p)})

    result = plugins.sort_by {|p|
      ordered_plugin_dirs.index(File.absolute_path(File.join(ASUtils.plugin_base_directory, p)))
    }

    result
  end

  MIGRATIONS_DIR = File.join(File.dirname(__FILE__), "migrations")
  PLUGIN_MIGRATIONS = []
  PLUGIN_MIGRATION_DIRS = {}

  order_plugins(AppConfig[:plugins]).each do |plugin|
    mig_dir = ASUtils.find_local_directories("migrations", plugin).shift
    if mig_dir && Dir.exist?(mig_dir)
      PLUGIN_MIGRATIONS << plugin
      PLUGIN_MIGRATION_DIRS[plugin] = mig_dir
    end
  end

  def self.setup_database(db)
    begin
      $db_type = db.database_type
      unless $db_type == :derby
        db.default_engine = 'InnoDB'
        db.default_charset = 'utf8'
      end

      fail_if_managed_container_migration_needed!(db)

      Sequel::Migrator.run(db, MIGRATIONS_DIR)
      PLUGIN_MIGRATIONS.each { |plugin| Sequel::Migrator.run(db, PLUGIN_MIGRATION_DIRS[plugin],
                                                             :table => "#{plugin}_schema_info") }
    rescue ContainerMigrationError
      raise $!
    rescue Exception => e
      $stderr.puts <<EOF

    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    !!                                                                                                !!
    !!                                      Database migration error.                                 !!
    !!                                  Your upgrade has encountered a problem.                       !!
    !!                  You must resolve these issues before the database migration can complete.     !!
    !!                                                                                                !!
    !!                                                                                                !!
    !!                                                Error:                                          !!
EOF
      e.message.split("\n").each do |line|
        $stderr.puts "    !! #{line}"
      end
      $stderr.puts <<EOF
    !!                                                                                                !!
    !!                                                                                                !!
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

EOF

      raise e
    end
  end


  CONTAINER_MIGRATION_NUMBER = 60

  class ContainerMigrationError < StandardError
  end

  def self.fail_if_managed_container_migration_needed!(db)
    # If brand new install with empty database, need to check
    # for tables existence before determining the current version number
    if db.tables.empty?
      current_version = 0
    else
      current_version = db[:schema_info].first[:version]
    end

    if current_version && current_version > 0 && current_version < CONTAINER_MIGRATION_NUMBER
      $stderr.puts <<~EOM

        =======================================================================
        Important migration issue
        =======================================================================

        Hello!

        It appears that you are upgrading ArchivesSpace from version 1.4.2 or prior.  To
        complete this upgrade, there are some additional steps to follow.

        The 1.5 series of ArchivesSpace introduced a new data model for containers,
        along with a compatibility layer to provide a seamless transition between the
        old and new container models.  In ArchivesSpace version 2.1, this compatibility
        layer was removed in the interest of long-term maintainability and system
        performance.

        To upgrade your ArchivesSpace installation, you will first need to upgrade to
        version 2.0.1.  This will upgrade your containers to the new model and clear the
        path for future upgrades.  Once you have done this, you can upgrade to the
        latest ArchivesSpace version as normal.

        For more information on upgrading to ArchivesSpace 2.0.1, please see the upgrade
        guide:

          https://archivesspace.github.io/tech-docs/administration/upgrading.html

        The upgrade guide for version 1.5.0 also contains specific instructions for
        the container upgrade that you will be performing, and the steps in this guide
        apply equally to version 2.0.1.  You can find that guide here:

          https://github.com/archivesspace/archivesspace/blob/master/UPGRADING_1.5.0.md

        =======================================================================

      EOM

      raise ContainerMigrationError.new
    end
  end


  def self.nuke_database(db)
    $db_type = db.database_type

    if $db_type == :mysql
      db.run('SET foreign_key_checks = 0;')
      db.drop_table?(*db.tables)
      db.run('SET foreign_key_checks = 1;')
    else
      PLUGIN_MIGRATIONS.reverse.each { |plugin| Sequel::Migrator.run(db, PLUGIN_MIGRATION_DIRS[plugin],
        :table => "#{plugin}_schema_info", :target => 0) }
      Sequel::Migrator.run(db, MIGRATIONS_DIR, :target => 0)
    end
  end

  def self.needs_updating?(db)
    $db_type = db.database_type
    return true unless Sequel::Migrator.is_current?(db, MIGRATIONS_DIR)
    PLUGIN_MIGRATIONS.each { |plugin| return true unless Sequel::Migrator.is_current?(db, PLUGIN_MIGRATIONS_DIR[plugin],
                                                                                      :table => "#{plugin}_schema_info") }
    return false
  end

  def self.latest_migration_number(db)
    migration_numbers = Dir.entries(MIGRATIONS_DIR).map {|e|
      if e =~ Sequel::Migrator::MIGRATION_FILE_PATTERN
        # $1 is the migration number (e.g. '075')
        Integer($1, 10)
      end
    }.compact

    if migration_numbers.empty?
      0
    else
      migration_numbers.max
    end
  end
end
