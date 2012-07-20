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
