require 'bundler'
Bundler.require

require 'sinatra'
require 'java'
require 'rspec'

if ENV['COVERAGE_REPORTS'] == 'true'
  require 'aspace_coverage'
  ASpaceCoverage.start('backend:test')
end

require_relative "../app/model/db"
require_relative "json_record_spec_helper"
require_relative "custom_matchers"

require 'digest/sha1'
require 'tmpdir'
require 'fileutils'


Dir.glob(File.join(File.dirname(__FILE__), '../', '../', 'common', 'lib', "*.jar")).each do |file|
  require file
end



# Use an in-memory Derby DB for the test suite
class DB

  def self.get_default_pool
    @default_pool
  end

  def self.mock_after_commit
    Thread.current[:after_commit_procs] = []

    result = yield

    Thread.current[:after_commit_procs].each do |block|
      block.call
    end

    result
  end

  class DBPool

    def build_migration_file_checksum(migration_dirs)
      Digest::SHA1.hexdigest(migration_dirs.map {|migration_dir|
                               Dir.glob(File.join(migration_dir, "*.rb"))
                             }.flatten.sort.inspect)
    end

    def connect
      # If we're not connected, we're in the process of setting up the primary
      # DB pool, so go ahead and connect to an in-memory Derby instance.
      if DB.get_default_pool == :not_connected
        require "db/db_migrator"

        if ENV['ASPACE_TEST_DB_URL']
          test_db_url = ENV['ASPACE_TEST_DB_URL']
        else
          test_db_url = "jdbc:derby:memory:fakedb;create=true"

          begin
            java.lang.Class.for_name("org.h2.Driver")
            test_db_url = "jdbc:h2:mem:test;DB_CLOSE_DELAY=-1"
          rescue java.lang.ClassNotFoundException
            # Oh well.  Derby it is!
          end
        end

        dumpfile = File.join(Dir.tmpdir, "aspace_test_derby_dump.dmp")
        migration_dirs = ([DBMigrator::MIGRATIONS_DIR] + DBMigrator::PLUGIN_MIGRATION_DIRS.values)

        if test_db_url =~ /derby/ && File.exist?(dumpfile)
          needs_refresh = false

          # If any of our migrations files is newer than our dump, the dump needs to be refreshed.
          needs_refresh ||= migration_dirs.any? {|migration_dir|
            Dir.glob(File.join(migration_dir, "*.rb")).any? {|migration|
              File.mtime(migration) >= File.mtime(dumpfile)
            }
          }

          # If the checksum has evaporated, we need a refresh, obvs!
          needs_refresh ||= !File.exist?(File.join(dumpfile, "checksum.txt"))

          # If new plugins were installed or removed, we need a refresh for that too
          needs_refresh ||= (File.read(File.join(dumpfile, "checksum.txt")) != build_migration_file_checksum(migration_dirs))

          if needs_refresh
            FileUtils.rm_rf(dumpfile)
          else
            puts "Loading initial DB state from copy: #{dumpfile}"
            test_db_url = "jdbc:derby:memory:fakedb;restoreFrom=#{dumpfile}/fakedb"
            ENV['ASPACE_TEST_DB_PERSIST'] = '1'
          end
        end

        @pool = Sequel.connect(test_db_url,
                               :max_connections => 10,
                               #:loggers => [Logger.new($stderr)]
                              )

        unless ENV['ASPACE_TEST_DB_PERSIST']
          DBMigrator.nuke_database(@pool)
        end

        DBMigrator.setup_database(@pool)

        if test_db_url =~ /derby/ && !ENV['ASPACE_TEST_DB_PERSIST']
          FileUtils.rm_rf(dumpfile) if File.exist?(dumpfile)
          @pool.run("CALL SYSCS_UTIL.SYSCS_BACKUP_DATABASE('#{dumpfile}')")
          File.write(File.join(dumpfile, "checksum.txt"), build_migration_file_checksum(migration_dirs))
          puts "Wrote new unit test DB cache to #{dumpfile}.  Subsequent runs will load this to avoid remigrations."
        end

        self
      else
        # For the sake of our tests, have all pools share the same Derby.
        DB.get_default_pool
      end
    end

    # The unit tests rely on transactions to rollback their side-effects, so
    # after commit hooks would ordinarily never fire.  Most code under test
    # doesn't care anyway, but code that does can wrap the relevant parts in
    # DB.mock_after_commit to have those after commit hooks fire at a known
    # point.
    #
    def after_commit(&block)
      if Thread.current[:after_commit_procs]
        Thread.current[:after_commit_procs] << block
      end
    end
  end
end


require 'rack/test'
require_relative "../app/lib/bootstrap"
require_relative "../../common/jsonmodel_translatable.rb"
ASpaceEnvironment.init(:unit_test)

AppConfig[:search_user_secret] = "abc123"

DB.connect
require_relative "../app/model/backend_enum_source"
JSONModel::init(:client_mode => true, :strict_mode => true,
                :url => 'http://example.com', :allow_other_unmapped => true,
                :enum_source => BackendEnumSource,
                :mixins => [JSONModelTranslatable],
                :i18n_source => I18n,
                :priority => :high)

module JSONModel
  module HTTP

    extend Rack::Test::Methods

    def self.multipart_request(uri, params)
      Struct.new(:method, :path, :body).new("POST", uri, params)
    end


    def self.do_http_request(url, req)
      send(req.method.downcase.intern, req.path, req.body)

      last_response.instance_eval do
        def code; status.to_s; end
      end

      last_response
    end
  end
end


# Switch off notifications for the tests
require_relative '../app/lib/notifications'
class Notifications

  def self.notify(*ignored)
    @last_notification = "#{(Time.now.to_f * 1000)}_#{rand}"
  end

  def self.last_notification
    @last_notification
  end

end


require_relative "../app/main"

Log.quiet_please

class ArchivesSpaceService
  class ExceptionPrintingMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      out = @app.call(env)

      if out[0] == 500
        raise env['sinatra.error']
      end

      out
    end
  end

  use ExceptionPrintingMiddleware


  def current_user
    Thread.current[:active_test_user] or raise "Unknown user"
  end

  def high_priority_request?
    # Always treat the request as high priority to make sure updates get sent to
    # the realtime indexer.
    true
  end

end


def app
  ArchivesSpaceService
end


require_relative 'factories'
require_relative "spec_helper_methods"


RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include FactoryBot::Syntax::Methods
  config.include SpecHelperMethods
  config.include JSONModel

  
  config.expect_with(:rspec) do |c|
    c.syntax = [:should, :expect]
  end

  # inclusions not in effect here
  config.before(:suite) do
    DB.open(true) do
      SpecHelperMethods.as_test_user("admin") do
        RequestContext.open do
          FactoryBot.create(:agent_corporate_entity)
          FactoryBot.create(:repo)
          $default_repo = $repo_id
          $repo_record = JSONModel.JSONModel(:repository).find($repo_id)
        end
      end
    end
  end


#  Roll back the database after each test
  config.around(:each) do |example|

    if example.metadata[:skip_db_open]
      # Running test without opening the DB first or rolling back after!
      example.run

    else

      DB.open(true) do |db|
        $testdb = db
        as_test_user("admin") do
          RequestContext.open do
            $repo_id = $default_repo
            $repo = JSONModel(:repository).uri_for($repo_id)
            JSONModel::set_repository($repo_id)
            RequestContext.put(:repo_id, $repo_id)
            RequestContext.put(:current_username, "admin")
            example.run
          end
        end
        raise Sequel::Rollback
      end

    end

    if ENV['ASPACE_TEST_DEBUG']
      puts example.metadata[:description]

      DB.open(true) do |db|
        puts "----DB Artifacts: ---"
        [:archival_object, :resource].each do |table|
          puts db[table].all
        end
        puts "----------------------"
      end
    end
  end

end
