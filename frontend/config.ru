# This file is used by Rack-based servers to start the application.

require "rubygems"
bundled_gems = Gem.path.find_all { |path| path =~ /WEB-INF/ }

# Blow away any paths we've picked up from the environment.
ENV['GEM_HOME'] = nil
ENV['GEM_PATH'] = nil

Gem.use_paths(nil, bundled_gems)


require ::File.expand_path('../config/environment',  __FILE__)
run ArchivesSpace::Application
