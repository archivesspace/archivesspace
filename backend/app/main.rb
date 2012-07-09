require_relative 'bootstrap'

require 'sinatra/base'


class ArchivesSpaceService < Sinatra::Base

  enable :sessions

  configure :development do |config|
    require 'sinatra/reloader'
    register Sinatra::Reloader
    config.also_reload "**/*.rb"
  end

  configure do
    set :logging, true
  end


  get '/' do
    "Hello, ArchivesSpace!"
  end

end


if $0 == __FILE__
  Log.info("Dev server starting up...")
  ArchivesSpaceService.run!
end
