# frozen_string_literal: true

require 'json'
require 'yaml'
require_relative 'scripts/tasks/check'
task default: ['check:multiple_gem_versions']

namespace :check do
  GEMS_PATH = File.join(__dir__, 'build', 'gems', 'gems', '*')
  LOCALES_DIRS = [
    File.join(__dir__, 'common', 'locales'),
    File.join(__dir__, 'common', 'locales', 'enums'),
    File.join(__dir__, 'frontend', 'config', 'locales'),
    File.join(__dir__, 'frontend', 'config', 'locales', 'help'),
    File.join(__dir__, 'public', 'config', 'locales')
  ]

  desc 'Check for missing keys in locale files compared to :en'
  task :locales do
    Check.run(Check::Locales.new(LOCALES_DIRS))
  end

  desc 'Check for multiple versions of a gem in the build directory'
  task :multiple_gem_versions do
    Check.run(Check::Gems.new(GEMS_PATH))
  end
end
