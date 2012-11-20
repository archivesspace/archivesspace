require 'net/http'
require 'uri'
require 'json'
require 'fileutils'

require_relative '../common/jsonmodel'
require_relative '../common/jsonmodel_client'
require_relative '../config/config-distribution'


class IndexState

  def initialize
    @state_dir = File.join(AppConfig[:data_directory], "indexer_state")

    FileUtils.mkdir_p(@state_dir)
  end


  def path_for(repository, record_type)
    File.join(@state_dir, "#{repository.id}_#{record_type}")
  end


  def set_last_mtime(repository, record_type, time)
    path = path_for(repository, record_type)

    File.open("#{path}.tmp", "w") do |fh|
      fh.puts(time.to_i)
    end

    File.rename("#{path}.tmp", "#{path}.dat")
  end


  def get_last_mtime(repository, record_type)
    path = path_for(repository, record_type)

    begin
      File.open("#{path}.dat", "r") do |fh|
        fh.readline.to_i
      end
    rescue Errno::ENOENT
      # If we've never run against this repository/type before, just index
      # everything.
      0
    end
  end
end


class ArchivesSpaceIndexer

  include JSONModel

  @@record_types = [:accession, :archival_object, :resource, :digital_object, :digital_object_component]
  @current_session = nil


  def initialize
    JSONModel::init(:client_mode => true, :url => AppConfig[:backend_url])
    @state = IndexState.new
  end


  def solr_url
    URI.parse(AppConfig[:solr_url])
  end


  def do_http_request(url, req)
    req['X-ArchivesSpace-Session'] = @current_session

    Net::HTTP.start(url.host, url.port) do |http|
      http.request(req)
    end
  end


  def reset_session
    @current_session = nil
  end


  def login
    if @current_session
      return @current_session
    end

    username = AppConfig[:search_username]
    password = AppConfig[:search_user_secret]

    url = URI.parse(AppConfig[:backend_url] + "/users/#{username}/login")

    request = Net::HTTP::Post.new(url.request_uri)
    request.set_form_data("expiring" => "false",
                          "password" => password)

    response = do_http_request(url, request)

    if response.code == '200'
      auth = JSON.parse(response.body)

      JSONModel::HTTP.current_backend_session = auth['session']

    else
      raise "Authentication to backend failed: #{response.body}"
    end
  end


  def index_records(records, type)
    batch = []

    records.each do |record|
      doc = {}

      doc[:id] = record.uri
      doc[:title] = record[:title]
      doc[:type] = type
      doc[:fullrecord] = record.to_json
      doc[:suppressed] = record[:suppressed].to_s

      batch << doc
    end

    if !batch.empty?
      req = Net::HTTP::Post.new("/update")
      req['Content-Type'] = 'application/json'
      req.body = {:add => batch}.to_json

      puts "Indexing #{batch.length} documents: #{do_http_request(solr_url, req)}"
    end

  end


  def send_commit
    req = Net::HTTP::Post.new("/update")
    req['Content-Type'] = 'application/json'
    req.body = {:commit => {}}.to_json

    do_http_request(solr_url, req)
  end


  def run_index_round
    puts "#{Time.now}: Running index round"

    login

    JSONModel(:repository).all.each do |repository|
      JSONModel.set_repository(repository.id)

      @@record_types.each do |type|
        start = Time.now
        page = 1
        while true
          records = JSONModel(type).all(:page => page,
                                        :modified_since => @state.get_last_mtime(repository, type))

          index_records(records['results'], type)

          break if records['last_page'] <= page
          page += 1
        end

        @state.set_last_mtime(repository, type, start)
      end
    end

    send_commit
  end


  def run
    while true
      begin
        run_index_round
      rescue
        reset_session
        puts "#{$!.inspect}"
      end

      # FIXME: make this configurable
      sleep 30
    end
  end


  def self.main
    indexer = ArchivesSpaceIndexer.new

    indexer.run
  end

end


ArchivesSpaceIndexer.main
