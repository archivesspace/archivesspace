require_relative '../../launcher_init'
require_relative '../../request_handler'
require 'config/config-distribution'
require 'tempfile'
require 'zip/zip'

class ArchivesSpaceEadExporter

  include RequestHandler
  attr_reader :repo_id

  def initialize(repo_id)
    @repo_id = repo_id
    @token = nil
  end

  def export(id)
    params = "include_unpublished=false&include_daos=true&numbered_cs=true"
    url = URI("#{AppConfig[:backend_url]}/repositories/#{repo_id}/resource_descriptions/#{id}.xml?#{params}")
    get(url, :xml)
  end

  def resource_ids
    url = URI("#{AppConfig[:backend_url]}/repositories/#{repo_id}/resources?all_ids=true")
    get(url)
  end

end

def main
  if ARGV.length != 3
    puts "Usage: export.rb <username> <password> <repository_id>"
    exit
  end
  user, password, repository_id = *ARGV

  exporter = ArchivesSpaceEadExporter.new(repository_id)
  exporter.login(user, password)

  ids = exporter.resource_ids
  if ids.any?
    zip_filename = "#{AppConfig[:data_directory]}/export-repo-#{repository_id}.zip"
    # for now at least blow away any existing zip file
    File.delete zip_filename if File.exists? zip_filename
    zip = Zip::File.new(zip_filename, Zip::File::CREATE)

    ids.each do |id|
      ead = exporter.export id
      unitid = ead.css("did unitid").first
      next if unitid.nil? # unpublished

      unitid = unitid.text.gsub(/(\/|\s)/, '_')
      ead_filename = "#{id}-#{unitid}.xml"
      tmp = Tempfile.new(ead_filename)
      tmp.write ead.to_s
      tmp.close

      zip.add "#{ead_filename}", tmp.path
      zip.commit

      tmp.unlink
    end

    zip.close
  end
end

main

