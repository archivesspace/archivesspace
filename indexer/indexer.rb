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

  @@record_types = [:accession, :archival_object, :resource, :digital_object, :digital_object_component, :collection_management, :subject, :location]
  @current_session = nil


  def initialize(state = nil)
    JSONModel::init(:client_mode => true, :url => AppConfig[:backend_url])
    @state = state || IndexState.new
    @document_prepare_hooks = []
  end


  def add_document_prepare_hook(&block)
    @document_prepare_hooks << block
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
      doc[:fullrecord] = record.to_json(:max_nesting => false)
      doc[:suppressed] = record[:suppressed].to_s

      @document_prepare_hooks.each do |hook|
        hook.call(doc, record)
      end

      batch << doc
    end

    if !batch.empty?
      req = Net::HTTP::Post.new("/update")
      req['Content-Type'] = 'application/json'
      req.body = {:add => batch}.to_json

      response = do_http_request(solr_url, req)
      puts "Indexed #{batch.length} documents: #{response}"

      if response.code != '200'
        raise "Error when indexing records: #{response.body}"
      end
    end

  end


  def send_commit
    req = Net::HTTP::Post.new("/update")
    req['Content-Type'] = 'application/json'
    req.body = {:commit => {}}.to_json

    response = do_http_request(solr_url, req)

    if response.code != '200'
      raise "Error when committing: #{response.body}"
    end
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

        send_commit
        @state.set_last_mtime(repository, type, start)
      end
    end

  end


  def run
    while true
      begin
        run_index_round
      rescue
        reset_session
        puts "#{$!.inspect}"
      end

      sleep AppConfig[:solr_indexing_frequency_seconds].to_i
    end
  end


  def self.get_indexer(state = nil)
    indexer = ArchivesSpaceIndexer.new(state)

    indexer.add_document_prepare_hook {|doc, record|
      if record.class.record_type == 'archival_object'
        doc['resource'] = record['resource']
      end
    }

    indexer.add_document_prepare_hook {|doc, record|
      if record.class.record_type == 'digital_object_component'
        doc['digital_object'] = record['digital_object']
      end
    }

    indexer.add_document_prepare_hook {| doc, record|
      if ['subject', 'location'].include?(record.class.record_type)
        doc['json'] = record.to_json
      end
    }

    indexer
  end


  def self.main
    indexer = get_indexer
    indexer.run
  end

end


if $0 == __FILE__
  ArchivesSpaceIndexer.main
end