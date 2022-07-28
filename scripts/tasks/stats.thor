require 'bundler'
Bundler.require
require 'csv'

def gh_client(token)
  # see http://piotrmurach.github.io/github/
  github = Github.new do |config|
    config.basic_auth = token unless token.nil?
    config.user = "archivesspace"
    config.repo = "archivesspace"
  end
  github
end


class Stats < Thor

  desc "downloads", "fetch release download stats from Github"
  option :token, :required => false
  def downloads
    github = gh_client(options[:token])
    csv =  CSV.open('track-release-downloads.csv', 'a')
    releases = github.repos.releases.list('archivesspace', 'archivesspace')
    releases.each do |release|
      release.assets.each do |asset|
        csv << [release.id,
                release.tag_name,
                asset.name,
                asset.download_count,
                asset.created_at,
                Time.now.to_s]
      end
    end
    csv.close
  end
end
