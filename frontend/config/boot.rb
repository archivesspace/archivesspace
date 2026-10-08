require 'rubygems'
require 'stringio'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'aspace_gems'
ASpaceGems.setup

# An explicit Bundler.setup (rather than `require 'bundler/setup'`) stops jruby-rack >= 1.2.8 from
# running Bundler itself before ASpaceGems.setup above has pointed it at the bundled gems
if File.exist?(ENV['BUNDLE_GEMFILE'])
  require 'bundler'
  Bundler.setup
end
require 'logger'
