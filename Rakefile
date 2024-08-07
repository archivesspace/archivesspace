# frozen_string_literal: true

# Rakefile for build / release supporting tasks
require 'date'
require 'digest'
require 'git'
require 'net/http'
require 'json'
require 'yaml'
require_relative 'scripts/tasks/check'
require_relative 'scripts/tasks/release_notes'
task default: ['check:multiple_gem_versions']

namespace :check do
  GEMS_PATH = File.join(__dir__, 'build', 'gems', 'jruby', '3.1.0', 'gems', '*')
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

# This is a legacy task, see the newer thor task for updated version
namespace :release_notes do
  # Requires setting ENV["REL_NOTES_TOKEN"] in the form of:
  # export REL_NOTES_TOKEN="github-user-name:personal-access-token"
  # or, for example:
  # export REL_NOTES_TOKEN="lorawoodford:12345"
  # See: https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/creating-a-personal-access-token
  # The token only needs to have the following scope: public_repo, repo:status
  # Intended use:
  # bundle exec rake release_notes:generate[$current_milestone,$previous_milestone,style]
  # bundle exec rake release_notes:generate[2.8.1,2.8.0]
  desc 'Generate a release notes formatted document between commits'
  task :generate, [:milestone, :old_milestone, :style] do |_t, args|
    milestone = args.fetch(:milestone)
    old_milestone = args.fetch(:old_milestone)
    style  = args.fetch(:style, 'brief')
    log = ReleaseNotes::GitLogParser.run(
      milestone: milestone
    )
    puts ReleaseNotes::Generator.new(
      version: milestone,
      log: log,
      old_milestone: old_milestone,
      style: style).process
  end
end

namespace :http do
  namespace :checksum do
    # bundle exec rake http:checksum:solr["http://localhost:8983/solr/archivesspace","schema.xml"]
    task :solr, [:base_url, :file] do |_t, args|
      file = args[:file]
      raise 'Invalid file' unless ['schema.xml', 'solrconfig.xml'].include? file

      path = "admin/file?file=#{file}&contentType=text%2Fxml%3Bcharset%3Dutf-8"
      url = URI(File.join(args[:base_url], path))
      internal_checksum = Digest::SHA2.hexdigest(File.read(File.join('solr', file)))
      external_checksum = Digest::SHA2.hexdigest(Net::HTTP.get_response(url).body)

      if internal_checksum != external_checksum
        raise 'Solr checksums do not match. Check configuration and try again.'
      end

      puts internal_checksum
    end
  end
end
