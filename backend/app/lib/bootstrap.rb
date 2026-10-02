require 'rubygems'
require 'java'
require 'sequel'
require 'sequel/plugins/def_dataset_method'
require 'sequel/plugins/optimistic_locking'
Sequel.extension :pagination
Sequel.extension :core_extensions
Sequel::Model.require_valid_table = false
Sequel::Model.plugin :def_dataset_method


# Turn off the 'after_commit' and 'after_rollback' hooks on Sequel::Model.
# We don't use them anywhere, and they would otherwise cause a pair of
# blocks to be stored in memory every time we call '.save' (which in turn
# capture the record being saved and stop it being GC'd until the
# transaction finally commits).  When we're doing large batch imports (and
# committing at the end) that's a lot of memory!
# Sequel::Model.use_after_commit_rollback = false # DEPRECATED: Sequel 5.1.0


require "db/db_migrator"

require 'fileutils'
require "jsonmodel"
require "asutils"
require "ashttp"
require "asconstants"
require 'open-uri'
require 'aspace_i18n'
require 'logger'
require 'log'
require_relative 'exceptions'
require 'config/config-distribution'
require_relative 'username'

if AppConfig[:backend_log] == 'default'
  Log.logger($stderr)
else
  Log.logger(AppConfig[:backend_log])
end

class ASpaceEnvironment

  def self.environment
    @environment
  end


  def self.init(environment = :auto)
    return if @environment      # Already initialised

    if environment != :auto
      @environment = environment
    elsif ENV["ASPACE_INTEGRATION"] == "true"
      @environment = :integration
    else
      @environment = :production
    end

    prepare_data_directory
  end

  def self.prepare_data_directory
    if @environment != :unit_test
      FileUtils.mkdir_p(AppConfig[:data_directory])
    end
  end

end
