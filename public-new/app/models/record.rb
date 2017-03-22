class Record

  include ManipulateNode
  include JsonHelper
  include RecordHelper

  attr_reader :raw, :full, :json, :display_string, :container_display, :notes,
              :dates, :external_documents, :resolved_repository,
              :resolved_resource, :resolved_top_container, :primary_type, :uri,
              :subjects, :agents, :extents, :repository_information,
              :identifier, :classifications

  attr_accessor :criteria 

  ABSTRACT = %w(abstract scopecontent)

  def initialize(solr_result, full = false)
    @raw = solr_result
    if solr_result['json'].kind_of? Hash
      @json = solr_result['json']
    else
      @json = ASUtils.json_parse(solr_result['json']) || {}
    end

    @full = full

    @primary_type = raw['primary_type']
    @uri = raw['uri']
    @identifier = parse_identifier

    @display_string = parse_full_title
    @container_display = parse_container_display
    @notes =  parse_notes
    @dates = parse_dates
    @external_documents = parse_external_documents
    @resolved_repository = parse_repository
    @resolved_resource = parse_resource
    @resolved_top_container = parse_top_container
    @repository_information = parse_repository_info
    @subjects = parse_subjects
    @classifications = parse_classifications
    @agents = parse_agents(subjects)
    @extents = parse_extents
  end

  def [](k)
    $stderr.puts "FIXME stop direct access to the result json blob ([]): #{caller.first}"

    if k == 'json'
      json
    else
      raw[k]
    end
  end

  def dig(*args)
    $stderr.puts "FIXME stop direct access to the result json blob (dig): #{caller.first}"

    json.dig(args)
  end

  def note(type)
    notes[type] || {}
  end

  private

  def parse_full_title
    ft =  strip_mixed_content(json['display_string'] || json['title'])
    unless json['title_inherited'].blank? || (json['display_string'] || '') == json['title']
      ft = I18n.t('inherited', :title => strip_mixed_content(json['title']), :display => ft)
    end
    ft
  end

  def parse_identifier
    json.dig('_composite_identifier') || json.dig('component_id') ||  json.dig('id_0')
  end

  def parse_container_display
    containers = []

    if !json['instances'].blank? && json['instances'].kind_of?(Array)
      json['instances'].each do |inst|
        if inst.kind_of?(Hash) && inst['container'].present? && inst['container'].kind_of?(Hash)
          display = []
          %w{1 2 3}.each do |i|
            type = process_container_type(inst['container']["type_#{i}"])
            if !inst['container']["indicator_#{i}"].blank?
              display.push("#{type} #{inst['container']["indicator_#{i}"]}".gsub("Unspecified", ''))

            end
          end
          containers.push(display.join(", ")) unless display.empty?
        end
      end
    end

    containers
  end

  def parse_notes
    notes = {}

    if json.has_key?('notes')
      notes_html =  process_json_notes(json['notes'], (!full ? ABSTRACT : nil))
      notes_html.each do |type, html|
        notes[type] = html
      end
    end

    notes
  end

  def parse_dates
    return unless json.has_key?('dates') && full

    dates = []

    json['dates'].each do |date|
      label = date['label'].blank? ? '' : "#{date['label'].titlecase}: "
      label = '' if label == 'Creation: '
      exp =  date['expression'] || ''
      if exp.blank?
        exp = date['begin'] unless date['begin'].blank?
        unless date['end'].blank?
          exp = (exp.blank? ? '' : exp + '-') + date['end']
        end
      end
      if date['date_type'] == 'bulk'
        exp = exp.sub('bulk','').sub('()', '').strip
        exp = date['begin'] == date['end'] ? I18n.t('bulk._singular', :dates => exp) :
          I18n.t('bulk._plural', :dates => exp)
      end
      dates.push({'final_expression' => label + exp, '_inherited' => date.dig('_inherited')})
    end

    dates
  end

  def parse_external_documents
    return if !json.has_key?('external_documents') || json['external_documents'].blank?

    external_documents = []

    json['external_documents'].each do |doc|
      if doc['publish']
        extd = {}
        extd['title'] = doc['title']
        extd['uri'] = doc['location'].start_with?('http') ? doc['location'] :  ''
        external_documents.push(extd)
      end
    end

    external_documents
  end

  def parse_repository
    if raw['_resolved_repository'].kind_of?(Hash)
      rr = raw['_resolved_repository'].first

      if !rr[1][0]['json'].blank?
        return JSON.parse( rr[1][0]['json'])
      end
    end
  end

  def parse_resource
    if raw['_resolved_resource'].kind_of?(Hash)
      keys  = raw['_resolved_resource'].keys
      if keys
        rr = raw['_resolved_resource'][keys[0]]
        return  rr[0]
      end
    end
  end

  def parse_top_container
    if raw['_resolved_top_container_uri_u_sstr'].kind_of?(Hash)
#Pry::ColorPrinter.pp result['_resolved_top_container_uri_u_sstr']
      rr = raw['_resolved_top_container_uri_u_sstr'].first
      if !rr[1][0]['json'].blank?
        return JSON.parse( rr[1][0]['json'])
      end
    end
  end

  def process_container_type(in_type)
    type = ''
    if !in_type.blank?
      type = (in_type == 'unspecified' ?'': in_type)
#      type = 'box' if type == 'boxes'
#      type = type.chomp.chop if type.end_with?('s')
    end
    type
  end

  def parse_subjects
    return_arr = []

    ASUtils.wrap(json['subjects']).each do |subject|
      unless subject['_resolved'].blank?
        sub = title_and_uri(subject['_resolved'], subject['_inherited'])
        return_arr.push(sub) if sub
      end
    end

    return_arr
  end


  def parse_classifications
    return_arr = []

    ASUtils.wrap(json['classifications']).each do |c|
      unless c['_resolved'].blank?
        classification = record_from_resolved_json(c['_resolved'])
        return_arr << {
          'title' => classification.display_string,
          'uri' => classification.uri
        }
      end
    end

    return_arr
  end


  def title_and_uri(in_h, inh_struct = nil)
    ret_val = nil
    if in_h['publish']
      ret_val = in_h.slice('uri', 'title')
      ret_val['inherit'] = inheritance(inh_struct)
    end
    ret_val
  end

  def parse_agents(subjects_arr)
    agents_h = {}

    ASUtils.wrap(json['linked_agents']).each do |agent|
      unless agent['role'].blank? || agent['_resolved'].blank?
        role = agent['role']
        ag = title_and_uri(agent['_resolved'], agent['_inherited'])
        if role == 'subject'
          subjects_arr.push(ag) if ag
        elsif ag
          agents_h[role] = agents_h[role].blank? ? [ag] : agents_h[role].push(ag)
        end
      end
    end

    subjects_arr.sort_by! { |hsh| hsh['title'] }

    agents_h
  end

  def parse_extents
    results = []

    unless  json['extents'].blank?
      json['extents'].each do |ext|
        display = ''
        type = I18n.t("enumerations.extent_extent_type.#{ext['extent_type']}", default: ext['extent_type'])
        display = I18n.t('extent_number_type', :number => ext['number'], :type => type)
        summ = ext['container_summary'] || ''
        summ = "(#{summ})" unless summ.blank? || ( summ.start_with?('(') && summ.end_with?(')'))  # yeah, I coulda done this with rexep.
        display << ' ' << summ
        display << I18n.t('extent_phys_details',:deets => ext['physical_details']) unless  ext['physical_details'].blank?
        display << I18n.t('extent_dims', :dimensions => ext['dimensions']) unless  ext['dimensions'].blank?

        results.push({'display' => display, '_inherited' => ext.dig('_inherited')})
      end
    end

    results
  end

  def parse_repository_info
    info = {}
    info['top'] = {}
    unless resolved_repository.nil?
      %w(name uri url parent_institution_name image_url repo_code).each do | item |
        info['top'][item] = resolved_repository[item] unless resolved_repository[item].blank?
      end
      unless resolved_repository['agent_representation'].blank? || resolved_repository['agent_representation']['_resolved'].blank? || resolved_repository['agent_representation']['_resolved']['jsonmodel_type'] != 'agent_corporate_entity'
        in_h = resolved_repository['agent_representation']['_resolved']['agent_contacts'][0]
        %w{city region post_code country email }.each do |k|
          info[k] = in_h[k] if in_h[k].present?
        end
        if in_h['address_1'].present?
          info['address'] = []
          [1,2,3].each do |i|
            info['address'].push(in_h["address_#{i}"]) if in_h["address_#{i}"].present?
          end
        end
        info['telephones'] = in_h['telephones'] if !in_h['telephones'].blank?
      end
    end
    info
  end
  
  def archives_space_client
    @service ||= ArchivesSpaceClient.new
    @service
  end

  def cite_url_and_timestamp
    "#{AppConfig[:public_url].sub(/^\//, '')}#{uri}  #{I18n.t('accessed')}  #{Time.now.strftime("%B %d, %Y")}"
  end

end
