require 'sinatra'

require_relative '../app/lib/webhooks'

class Webhooks
  class << self
    alias :notify_orig :notify
  end

  def self.notify(*ignored)
  end
end


if ENV['COVERAGE_REPORTS'] == 'true'
  require 'tmpdir'
  require 'pp'
  require 'simplecov'

  SimpleCov.root(File.join(File.dirname(__FILE__), "../../"))
  SimpleCov.coverage_dir("backend/coverage")

  SimpleCov.start do
    # Not useful to include these since the test suite deliberately doesn't load
    # most of these files.
    add_filter "lib/bootstrap.rb"
    add_filter "lib/logging.rb"
    add_filter "config/"
    add_filter "model/db.rb"    # Overriden below

    # Leave gems out too
    add_filter "build/gems"
  end
end

require_relative "../app/model/db"


Thread.current[:test_mode] = true


# Use an in-memory Derby DB for the test suite
class DB
  def self.connect
    if not @pool
      require_relative "../app/model/db_migrator"
      @pool = Sequel.connect("jdbc:derby:memory:fakedb;create=true",
                             :max_connections => 10,
                             #:loggers => [Logger.new($stderr)]
                             )

      DBMigrator.nuke_database(@pool)
      DBMigrator.setup_database(@pool)
    end
  end
end


require 'rack/test'
require_relative "../app/lib/bootstrap"

JSONModel::init(:client_mode => true, :strict_mode => true,
                :url => 'http://example.com')

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

FactoryGirl.find_definitions
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
end


def as_test_user(username)
  old_user = Thread.current[:active_test_user]
  Thread.current[:active_test_user] = User.find(:username => username)
  begin
    yield
  ensure
    Thread.current[:active_test_user] = old_user
  end
end


DB.open(true) do
  RequestContext.open do
    create(:repo)
    $default_repo = $repo_id
  end
end


RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include FactoryGirl::Syntax::Methods

  # Roll back the database after each test
  config.around(:each) do |example|
    DB.open(true) do
      as_test_user("admin") do
        RequestContext.open do
          $repo_id = $default_repo
          $repo = JSONModel(:repository).uri_for($repo_id)
          JSONModel::set_repository($repo_id)
          RequestContext.put(:repo_id, $repo_id)
          example.run
        end
      end
      raise Sequel::Rollback
    end
  end
end
