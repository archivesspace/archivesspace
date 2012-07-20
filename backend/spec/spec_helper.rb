require File.join(File.dirname(__FILE__), '..', 'app', 'main.rb')

require 'sinatra'
require 'rack/test'

# setup test environment
set :environment, :test
set :run, false
set :raise_errors, true
set :logging, false

def app
  ArchivesSpaceService
end

RSpec.configure do |config|
  config.include Rack::Test::Methods
end

DB.connect
user_manager = UserManager.new
unless (user_manager.get_user("test1"))
  puts "creating test1 user ..."
  user_manager.create_user("test1", "Tester", "1", "local")
  db_auth = DBAuth.new
  db_auth.set_password("test1", "test1_123")
end
