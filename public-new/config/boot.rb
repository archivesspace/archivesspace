require 'rubygems'
require 'stringio'

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'aspace_gems'
ASpaceGems.setup

require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])
