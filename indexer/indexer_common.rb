require 'net/http'
require 'uri'
require 'json'
require 'fileutils'

require_relative '../common/asutils'
require_relative '../common/jsonmodel'
require_relative '../common/jsonmodel_client'
require_relative '../config/config-distribution'


class CommonIndexer

  include JSONModel

  @@record_types = [:accession, :archival_object, :resource,
                    :digital_object, :digital_object_component,
                    :collection_management, :subject, :location,
                    :agent_person, :agent_software, :agent_family, :agent_corporate_entity]

  @@resolved_attributes = ['subjects', 'linked_agents']


  def initialize(backend_url)
    @backend_url = backend_url
    @document_prepare_hooks = []
    @current_session = nil

    JSONModel::init(:client_mode => true, :url => @backend_url)

    configure_doc_rules
  end


  def add_subjects(doc, record)
    if record['record']['subjects']
      doc['subjects'] = record['record']['subjects'].map {|s| s['_resolved']['title']}.compact
    end
  end


  def add_audit_info(doc, record)
    #puts "******* #{record.inspect}"
    #doc['create_time'] =  
    #doc['last_modified'] = 
  end


  def configure_doc_rules
    add_document_prepare_hook {|doc, record|
      if doc['primary_type'] == 'archival_object'
        doc['resource'] = record['record']['resource']
      end
    }

    add_document_prepare_hook {|doc, record|
      add_subjects(doc, record)
      add_audit_info(doc, record)
    }

    add_document_prepare_hook {|doc, record|
      if doc['primary_type'] == 'accession'
        doc['accession_date_year'] = Date.parse(record['record']['accession_date']).year
      end
    }

    add_document_prepare_hook {|doc, record|
      if doc['primary_type'] == 'digital_object_component'
        doc['digital_object'] = record['record']['digital_object']
      end
    }

    add_document_prepare_hook {|doc, record|
      if ['agent_person', 'agent_family', 'agent_software', 'agent_corporate_entity'].include?(doc['primary_type'])
        doc['json'] = record['record'].to_json
        doc['title'] = record['record']['names'][0]['sort_name']

        # Assign the additional type of 'agent'
        doc['types'] << 'agent'
      end
    }

    add_document_prepare_hook {|doc, record|
      doc['external_id'] = Array(record['record']['external_ids']).map do |eid|
        eid['external_id']
      end
    }
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

    url = URI.parse(@backend_url + "/users/#{username}/login")

    request = Net::HTTP::Post.new(url.request_uri)
    request.set_form_data("expiring" => "false",
                          "password" => password)

    response = do_http_request(url, request)

    if response.code == '200'
      auth = ASUtils.json_parse(response.body)

      @current_session = auth['session']
      JSONModel::HTTP.current_backend_session = auth['session']

    else
      raise "Authentication to backend failed: #{response.body}"
    end
  end


  def get_record_scope(uri)
    JSONModel.parse_reference(uri)[:repository] || "global"
  end


  def delete_records(records)
    return if records.empty?

    req = Net::HTTP::Post.new("/update")
    req['Content-Type'] = 'application/json'
    req.body = {:delete => records.map {|id| {"id" => id}}}.to_json

    response = do_http_request(solr_url, req)
    puts "Deleted #{records.length} documents: #{response}"

    if response.code != '200'
      raise "Error when deleting records: #{response.body}"
    end
  end


  def index_records(records)
    batch = []

    records.each do |record|
      values = record['record']
      uri = record['uri']
      reference = JSONModel.parse_reference(uri)
      record_type = reference && reference[:type]

      if !record_type || !@@record_types.include?(record_type.intern)
        next
      end

      doc = {}

      doc['id'] = uri
      doc['title'] = values['title']
      doc['primary_type'] = record_type
      doc['types'] = [record_type]
      doc['fullrecord'] = values.to_json(:max_nesting => false)
      doc['suppressed'] = values['suppressed'].to_s
      doc['repository'] = get_record_scope(uri)

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


  def send_commit(type = :hard)
    req = Net::HTTP::Post.new("/update")
    req['Content-Type'] = 'application/json'
    req.body = {:commit => {"softCommit" => (type == :soft) }}.to_json

    response = do_http_request(solr_url, req)

    if response.code != '200'
      raise "Error when committing: #{response.body}"
    end
  end

end


