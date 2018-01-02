require 'config/config-distribution'
AppConfig[:frontend_proxy_url] = 'https://aspace.for/life'

require File.expand_path("../../config/environment", __FILE__)

require 'rspec/rails'
require 'capybara/rails'
