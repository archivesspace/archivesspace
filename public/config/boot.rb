require 'rubygems'
require 'stringio'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'aspace_gems'
ASpaceGems.setup

# Keep this an explicit Bundler.setup call and do not replace it with `require 'bundler/setup'`.
# jruby-rack >= 1.2.8 (RailsEnvironment#rails_has_default_bundler_boot?) runs Bundler.setup itself,
# before this file is loaded, when boot.rb requires 'bundler/setup' and never calls Bundler.setup.
# That would happen before ASpaceGems.setup above has pointed RubyGems at the bundled gems, and the
# deployed WARs would fail with GemNotFound (the devserver does not go through jruby-rack).
if File.exist?(ENV['BUNDLE_GEMFILE'])
  require 'bundler'
  Bundler.setup
end
require 'logger'
