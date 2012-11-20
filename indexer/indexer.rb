require 'net/http'
require 'uri'
require 'json'

require_relative '../common/jsonmodel'
require_relative '../common/jsonmodel_client'
require_relative '../config/config-distribution'


class ArchivesSpaceIndexer

  include JSONModel

  @@record_types = [:accession, :archival_object, :resource, :digital_object, :digital_object_component]


  def initialize
    JSONModel::init(:client_mode => true, :url => AppConfig[:backend_url])
  end


  def login
    username = AppConfig[:search_username]
    password = AppConfig[:search_user_secret]

    uri = URI.parse(AppConfig[:backend_url] + "/users/#{username}/login")

    response = Net::HTTP.post_form(uri,
                                   "expiring" => "false",
                                   "password" => password)

    puts "login response:"
    if response.code == '200'
      auth = JSON.parse(response.body)

      JSONModel::HTTP.current_backend_session = auth['session']

    else
      raise "Authentication to backend failed: #{response.body}"
    end
  end


  def index_records(records, type)
    records.each do |record|
      puts record
    end
  end


  def run
    login

    JSONModel(:repository).all.each do |repository|
      JSONModel.set_repository(repository.id)

      @@record_types.each do |type|
        page = 1
        while true
          records = JSONModel(type).all(:page => page)

          index_records(records['results'], type)

          break if records['last_page'] <= page
          page += 1
          puts "\n\nPage #{page}\n\n"

        end
      end

    end
  end


  def self.main
    indexer = ArchivesSpaceIndexer.new

    indexer.run
  end

end


ArchivesSpaceIndexer.main
