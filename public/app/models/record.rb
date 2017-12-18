class Record

  include ManipulateNode
  include JsonHelper
  include RecordHelper
  include PrefixHelper

  attr_reader :raw, :full, :json, :display_string, :container_display, :container_summary_for_badge,
              :notes, :dates, :external_documents, :resolved_repository,
              :resolved_resource, :resolved_top_container, :primary_type, :uri,
              :subjects, :agents, :extents, :repository_information,
              :identifier, :classifications, :level, :other_level, :linked_digital_objects,
              :container_titles_and_uris

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

    @resolved_resource = parse_resource

    @level = raw['level']
    @other_level = json['other_level']

    @display_string = parse_full_title
    @container_display = parse_container_display
    @container_summary_for_badge = parse_container_summary_for_badge
    @container_titles_and_uris = parse_container_display(:include_uri => true)
    @linked_digital_objects = parse_digital_object_instances
    @notes =  parse_notes
    @dates = parse_dates
    @external_documents = parse_external_documents
    @resolved_repository = parse_repository
    @resolved_top_container = parse_top_container
    @repository_information = parse_repository_info
    @subjects = parse_subjects
    @classifications = parse_classifications
    @agents = parse_agents(subjects)
    @extents = parse_extents
  end

  def [](k)
    if k == 'json'
      json
    else
      raw[k]
    end
  end

  def dig(*args)
    json.dig(args)
  end

  def note(type)
    notes[type] || {}
  end

  def request_item
    return unless RequestItem.allow_for_type(resolved_repository.dig('repo_code'), primary_type.intern)

    build_request_item
  end

  private

  def parse_full_title
    ft =  process_mixed_content(json['display_string'] || json['title'], :preserve_newlines => true)
    unless json['title_inherited'].blank? || (json['display_string'] || '') == json['title']
      ft = I18n.t('inherited', :title => process_mixed_content(json['title'], :preserve_newlines => true), :display => ft)
    end
    ft
  end

  def parse_identifier
    json.dig('_composite_identifier') || json.dig('component_id') ||
        ([json.dig('id_0'), json.dig('id_1'), json.dig('id_2'), json.dig('id_3')].select { |x| not(x.nil?) && not(x.empty?) }).join('-')
  end

  def parse_container_summary_for_badge
    parse_container_display(:summary => true)
  end

  def parse_container_display(opts = {})
    summary = opts.fetch(:summary, false)
    include_uri = opts.fetch(:include_uri, false)
    containers = []

    if !json['instances'].blank? && json['instances'].kind_of?(Array)
      json['instances'].each do |inst|
        sub_container = inst.fetch('sub_container', nil)

        next if sub_container.nil?

        container_display_string = parse_sub_container_display_string(sub_container, inst, opts)
        if include_uri && top_container_uri = sub_container.dig('top_container', 'ref')
          containers << {
            'title' => container_display_string,
            'uri' => top_container_uri
          }
        else
          containers << container_display_string
        end

        return I18n.t('multiple_containers') if summary && containers.length > 1
      end
    end

    if summary
      containers.empty? ? nil : containers[0]
    else
      containers
    end
  end

  def rewrite_refs(notes, base_uri)
    if notes.is_a?(Hash)
      notes.each do |k, v|
        if k == 'content' || k == 'items'
          ASUtils.wrap(v).each do |s|
            if s.is_a? String
              s.gsub!(/<ref .*?target="(.+?)".*?>(.+?)<\/ref>/m, "<a href='#{app_prefix(base_uri)}/resolve/\\1'>\\2</a>")
            else
              rewrite_refs(s, base_uri)
            end
          end
        else
          rewrite_refs(v, base_uri)
        end
      end
    elsif notes.is_a?(Array)
      notes.each do |note|
        rewrite_refs(note, base_uri)
      end
    end
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
    return unless (json.has_key?('dates') || json.has_key?('dates_of_existence')) && full

    dates = []

    (json['dates'] || json['dates_of_existence']).each do |date|
      label, exp = parse_date(date)
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
    elsif @json['repository'] && @json['repository']['_resolved']
      @json['repository']['_resolved']
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

  def parse_subjects
    return_arr = []

    ASUtils.wrap(json['subjects']).each do |subject|
      unless subject['_resolved'].blank?
        subject['_resolved']['is_inherited'] = subject.has_key?('_inherited')
        return_arr.push(subject['_resolved'])
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
          'uri' => classification.uri,
          'breadcrumb' => classification.breadcrumb
        }
      end
    end

    return_arr
  end

  def parse_agents(subjects_arr)
    agents_h = {}

    ASUtils.wrap(json['linked_agents']).each do |relationship|
      unless relationship['role'].blank? || relationship['_resolved'].blank?
        agent = relationship.fetch('_resolved')
        next unless agent['publish']

        role = relationship['role']

        if role == 'subject'
          subjects_arr.push(relationship['_resolved'].merge('_relator' => relationship['relator'], '_terms' => relationship['terms']))
        else
          agents_h[role] ||= []
          agents_h[role] << relationship
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
    ArchivesSpaceClient.instance
  end

  def cite_url_and_timestamp
    "#{AppConfig[:public_proxy_url].sub(/^\//, '')}#{uri}  #{I18n.t('accessed')}  #{Time.now.strftime("%B %d, %Y")}"
  end

  def top_container_for_uri(uri)
    if raw['_resolved_top_container_uri_u_sstr']
      resolved = raw['_resolved_top_container_uri_u_sstr'].fetch(uri, nil)

      if resolved
        resolved.first
      end
    end
  end

  def parse_top_container_location(top_container)
    container_locations = top_container.dig('container_locations')

    return if container_locations.blank?

    current_location = container_locations.find{|c| c['status'] == 'current'}

    current_location.dig('_resolved')
  end

  def parse_sub_container_display_string(sub_container, inst, opts = {})
    summary = opts.fetch(:summary, false)
    parts = []

    instance_type = I18n.t("enumerations.instance_instance_type.#{inst.fetch('instance_type')}", :default => inst.fetch('instance_type'))

    # add the top container type and indicator
    if sub_container.has_key?('top_container')
      top_container_solr = top_container_for_uri(sub_container['top_container']['ref'])
      if top_container_solr
        # We have a top container from Solr
        top_container_display_string = ""
        top_container_json = ASUtils.json_parse(top_container_solr.fetch('json'))
        if top_container_json['type']
          top_container_type = I18n.t("enumerations.container_type.#{top_container_json.fetch('type')}", :default => top_container_json.fetch('type'))
          top_container_display_string << "#{top_container_type}: "
        else
          top_container_display_string << "#{I18n.t('enumerations.container_type.container')}: "
        end
        top_container_display_string << top_container_json.fetch('indicator')
        parts << top_container_display_string
      elsif sub_container['top_container']['_resolved'] && sub_container['top_container']['_resolved']['display_string']
        # We have a resolved top container with a display string
        parts << sub_container['top_container']['_resolved']['display_string']
      end
    end


    # add the child type and indicator
    if sub_container['type_2'] && sub_container['indicator_2']
      type = I18n.t("enumerations.container_type.#{sub_container.fetch('type_2')}", :default => sub_container.fetch('type_2'))
      parts << "#{type}: #{sub_container.fetch('indicator_2')}"
    end

    # add the grandchild type and indicator
    if sub_container['type_3'] && sub_container['indicator_3']
      type = I18n.t("enumerations.container_type.#{sub_container.fetch('type_3')}", :default => sub_container.fetch('type_3'))
      parts << "#{type}: #{sub_container.fetch('indicator_3')}"
    end

    summary ? parts.join(", ") : "#{parts.join(", ")} (#{instance_type})"
  end

  def parse_digital_object_instances
    results = {}

    ASUtils.wrap(json['instances']).each do |instance|
      if instance['digital_object'] && instance['digital_object']['ref']
        digital_object = digital_object_for_uri(instance['digital_object']['ref'])
        next if digital_object.nil?

        results[instance['digital_object']['ref']] = record_from_resolved_json(digital_object)
      end
    end

    results
  end

  def digital_object_for_uri(uri)
    if raw['_resolved_digital_object_uris']
      resolved = raw['_resolved_digital_object_uris'].fetch(uri, nil)

      if resolved
        resolved.first
      end
    end
  end

  def build_request_item
    # handled by sub classes
    nil
  end

  def build_request_item_container_info
    container_info = {}

    %i(top_container_url container location_title location_url machine barcode).each {|sym| container_info[sym] = [] }

    unless json['instances'].blank?
      json['instances'].each do |instance|
        sub_container = instance.dig('sub_container')

        next if sub_container.nil?

        top_container_uri = sub_container.dig('top_container', 'ref');
        top_container = top_container_for_uri(top_container_uri)

        next if container_info.fetch(:top_container_url).include?(top_container_uri)

        hsh = {
          :container => parse_sub_container_display_string(sub_container, instance),
          :top_container_url => top_container_uri,
        }

        if top_container
          top_container_json = ASUtils.json_parse(top_container.fetch('json'))
          hsh[:barcode] = top_container_json.dig('barcode')

          location = parse_top_container_location(top_container_json)

          if (location)
            hsh[:location_title] = location.dig('title')
            hsh[:location_url] = location.dig('uri')
          else
            hsh[:location_title] = ''
            hsh[:location_url] = ''
          end

          restricts = top_container_json.dig('active_restrictions')
          if restricts
            restricts.each do |r|
              lar = r.dig('local_access_restriction_type')
              container_info[:machine] += lar if lar
            end
          end
        else
          hsh[:barcode] = ''
          hsh[:location_title] = ''
          hsh[:location_url] = ''
        end

        hsh.keys.each {|sym| container_info[sym].push(hsh[sym] || '')}
      end
    end

    container_info
  end

end
