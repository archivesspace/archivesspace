require 'bundler'
Bundler.require

require 'sinatra'
require 'java'

if ENV['COVERAGE_REPORTS'] == 'true'
  require 'aspace_coverage'
  ASpaceCoverage.start('backend:test')
end

require_relative "../app/model/db"


Thread.current[:test_mode] = true


# Use an in-memory Derby DB for the test suite
class DB
  def self.connect
    if not @pool
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

      @pool = Sequel.connect(test_db_url,
                             :max_connections => 10,
                             #:loggers => [Logger.new($stderr)]
                             )

      DBMigrator.nuke_database(@pool)
      DBMigrator.setup_database(@pool)
    end
  end


  # For the sake of unit tests, just fire these straight away (since the entire
  # test always runs in a transaction)
  def self.after_commit(&block)
    block.call
  end
end


require 'rack/test'
require_relative "../app/lib/bootstrap"
AppConfig[:search_user_secret] = "abc123"

DB.connect
require_relative "../app/model/backend_enum_source"
JSONModel::init(:client_mode => true, :strict_mode => true,
                :url => 'http://example.com', :allow_other_unmapped => true,
                :enum_source => BackendEnumSource,
                :priority => :high)

module JSONModel
  module HTTP

    extend Rack::Test::Methods


    def self.do_http_request(url, req)
      send(req.method.downcase.intern, req.path, params = req.body)

      last_response.instance_eval do
        def code; status.to_s; end
      end

      last_response
    end
  end
end


# Note: This import is loading JSONModel into the Object class.  Pretty gross!
# It would be nice if we could narrow the scope of this to just the tests.
include JSONModel


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
end


def app
  ArchivesSpaceService
end

require 'factory_girl'


# FactoryGirl.definition_file_paths = [File.dirname(__FILE__)]
# FactoryGirl.find_definitions
require_relative 'factories'
include FactoryGirl::Syntax::Methods


def make_test_repo(code = "ARCHIVESSPACE")
  repo = create(:repo, {:repo_code => code})

  @repo_id = repo.id
  @repo = JSONModel(:repository).uri_for(repo.id)

  JSONModel::set_repository(@repo_id)
  RequestContext.put(:repo_id, @repo_id)

  @repo_id
end


def make_test_user(username, name = "A test user", source = "local")
  create(:user, {:username => username, :name => name, :source => source})
end



class ArchivesSpaceService
  def current_user
    Thread.current[:active_test_user]
  end

  def high_priority_request?
    # Always treat the request as high priority to make sure updates get sent to
    # the realtime indexer.
    true
  end

end


def create_nobody_user
  user = create(:user, :username => 'nobody')

  viewers = JSONModel(:group).all(:group_code => "repository-viewers").first
  viewers.member_usernames = ['nobody']
  viewers.save

  user
end


def as_test_user(username)
  old_user = Thread.current[:active_test_user]
  Thread.current[:active_test_user] = User.find(:username => username)
  orig = RequestContext.get(:enforce_suppression)
  old_username = RequestContext.get(:current_username)

  begin
    if RequestContext.active?
      RequestContext.put(:enforce_suppression,
                         !Thread.current[:active_test_user].can?(:manage_repository))
      RequestContext.put(:current_username, username)
    end

    yield
  ensure
    RequestContext.put(:enforce_suppression, orig) if RequestContext.active?
    RequestContext.put(:current_username, old_username) if RequestContext.active?
    Thread.current[:active_test_user] = old_user
  end
end

def as_anonymous_user
  old_user = Thread.current[:active_test_user]
  orig = RequestContext.get(:enforce_suppression)

  Thread.current[:active_test_user] = AnonymousUser.new

  begin
    if RequestContext.active?
      RequestContext.put(:enforce_suppression, true)
    end

    yield
  ensure
    RequestContext.put(:enforce_suppression, orig) if RequestContext.active?
    Thread.current[:active_test_user] = old_user
  end
end


DB.open(true) do
  RequestContext.open do
    create(:agent_corporate_entity)
    create(:repo)
    $default_repo = $repo_id
  end
end


RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include FactoryGirl::Syntax::Methods

  # Roll back the database after each test
  config.around(:each) do |example|
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
end
