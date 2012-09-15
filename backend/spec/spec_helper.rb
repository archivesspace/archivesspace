require 'sinatra'

if ENV['COVERAGE_REPORTS']
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
                             # :loggers => [Logger.new($stderr)]
                             )

      DBMigrator.nuke_database(@pool)
      DBMigrator.setup_database(@pool)
    end
  end
end


require_relative "../app/main"
require 'rack/test'

JSONModel::init(:client_mode => true, :strict_mode => true,
                :url => 'http://example.com')
include JSONModel


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


def make_test_repo(code = "ARCHIVESSPACE")
  repo = JSONModel(:repository).from_hash("repo_code" => code,
                                          "description" => "A new ArchivesSpace repository")
  id = repo.save
  @repo = repo.uri

  JSONModel::set_repository(id)

  id
end


RSpec.configure do |config|
  config.include Rack::Test::Methods

  # Roll back the database after each test
  config.around(:each) do |example|
    DB.open(true) do
      example.run
      raise Sequel::Rollback
    end
  end
end
