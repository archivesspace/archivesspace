# frozen_string_literal: true

# Rakefile for build / release supporting tasks
require 'date'
require 'git'
require 'json'
require 'yaml'
require_relative 'scripts/tasks/check'
require_relative 'scripts/tasks/release_notes'
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

  # bundle exec rake check:locales
  desc 'Check for missing keys in locale files compared to :en'
  task :locales do
    Check.run(Check::Locales.new(LOCALES_DIRS))
  end

  # bundle exec rake check:multiple_gem_versions
  desc 'Check for multiple versions of a gem in the build directory'
  task :multiple_gem_versions do
    Check.run(Check::Gems.new(GEMS_PATH))
  end
end

namespace :release_notes do
  # Intended use:
  # bundle exec rake release_notes:generate[$previous_version,$current_version]
  # bundle exec rake release_notes:generate[v2.7.0,v2.7.1]
  # To view in development release notes:
  # bundle exec rake release_notes:generate[$current_version,master]
  # bundle exec rake release_notes:generate[v2.7.1,master]
  desc 'Generate a release notes formatted document between commits'
  task :generate, [:since, :target] do |_t, args|
    target = args.fetch(:target, 'master')
    log = ReleaseNotes::GitLogParser.run(
      path: __dir__,
      since: args.fetch(:since, 'master'),
      target: target
    )
    puts ReleaseNotes::Generator.new(version: target, log: log).process
  end
end
