require 'rubygems'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])


# Sort of hacky.  We'll have to clean this up somehow :)
require_relative "../../common/jsonmodel"
include JSONModel
