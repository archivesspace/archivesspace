require_relative '../../launcher_init'
require 'config/config-distribution'
require 'json'
require 'net/http'
require 'nokogiri'
require 'tempfile'
require 'zip/zip'

class ArchivesSpaceEadExporter

  attr_reader :repo_id, :token

  def initialize(repo_id)
    @repo_id = repo_id
    @token = nil
  end

  def login(user, password)
    url = URI("#{AppConfig[:backend_url]}/users/#{user}/login")
    @token = post(url, { "password" => password })["session"]
    token
  end

  ##### RESOURCE HANDLING

  def export(id)
    params = "include_unpublished=false&include_daos=true&numbered_cs=true"
    url = URI("#{AppConfig[:backend_url]}/repositories/#{repo_id}/resource_descriptions/#{id}.xml?#{params}")
    get(url, :xml)
  end

  def resource_ids
    url = URI("#{AppConfig[:backend_url]}/repositories/#{repo_id}/resources?all_ids=true")
    get(url)
  end

  ##### REQUEST HANDLING

  def get(url, format = :json)
    req = Net::HTTP::Get.new(url.request_uri)
    request url, req, format
  end

  def post(url, params)
    req = Net::HTTP::Post.new(url.request_uri)
    req.set_form_data(params)
    request url, req
  end

  def request(url, req, format = :json)
    req['X-ArchivesSpace-Session'] = @token
    Net::HTTP.start(url.host, url.port) do |http|
      response = http.request(req)
      if response.code =~ /^4/
        raise "Request error for #{url}: #{response.message}"
      end
      if format == :json
        JSON.parse response.body
      elsif format == :xml
        Nokogiri::XML response.body
      else
        raise "Request error unrecognized format for #{url}: #{format}"
      end
    end
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

      unitid = unitid.text
      ead_filename = "#{id}-#{unitid}"
      tmp = Tempfile.new(ead_filename)
      tmp.write ead.to_s
      tmp.close

      zip.add "#{ead_filename}.xml", tmp.path
      zip.commit

      tmp.unlink
    end

    zip.close
  end
end

main
