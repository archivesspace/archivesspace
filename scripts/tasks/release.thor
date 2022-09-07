require 'bundler'
Bundler.require
require_relative 'release_notes'

def gh_client(token)
  # see http://piotrmurach.github.io/github/
  github = Github.new do |config|
    config.basic_auth = token unless token.nil?
    config.user = "archivesspace"
    config.repo = "archivesspace"
  end
  github
end


class Release < Thor

  desc "status", "check release status"
  option :token, :required => false
  option :tag, :required => true
  def status
    github = gh_client(options[:token])
    release = github.repos.releases.tags.get('archivesspace', 'archivesspace', options[:tag])
    puts "Release Name: #{release.name}"
    puts "Pre-release: #{release.prerelease}"
    puts "Draft: #{release.draft}"
  end

  desc "make_draft", "make the release a draft"
  option :token, :required => false
  option :tag, :required => true
  def make_draft
    github = gh_client(options[:token])
    release = github.repos.releases.tags.get('archivesspace', 'archivesspace', options[:tag])
    github.repos.releases.update('archivesspace', 'archivesspace', release.id, draft: true)
  end
end
