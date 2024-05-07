# frozen_string_literal: true

class MARCAuthSerializer < ASpaceExport::Serializer
  serializer_for :marc_auth

  def serialize(marc, _opts = {})
    builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      _marc(marc, xml)
    end
    builder.to_xml.to_s
  end

  private

  def _marc(obj, xml)
    json = obj.json
    xml.collection(
      'xmlns' => 'http://www.loc.gov/MARC21/slim',
      'xmlns:marc' => 'http://www.loc.gov/MARC21/slim',
      'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
      'xsi:schemaLocation' => 'http://www.loc.gov/MARC21/slim https://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd'
    ) do
      xml.record do
        _leader(json, xml)
        _controlfields(json, xml)
        record_ids(json, xml)
        record_control(json, xml)
        dates_of_existence(json, xml)
        names(json, xml)
        places(json, xml)
        occupations(json, xml)

        if agent_type(json) == :person
          topics(json, xml)
          gender(json, xml)
        elsif agent_type(json) == :family || agent_type(json) == :corp
          functions(json, xml)
        end

        used_languages(json, xml)
        relationships(json, xml)
        sources(json, xml)
        notes(json, xml)
      end
    end
  end

  def _leader(json, xml)
    xml.leader do
      if json['agent_record_controls']&.any?
        arc = json['agent_record_controls'].first

        case arc['maintenance_status']
        when 'new'
          pos5 = 'n'
        when 'upgraded'
          pos5 = 'a'
        when 'revised_corrected'
          pos5 = 'c'
        when 'deleted'
          pos5 = 'd'
        when 'cancelled_obsolete'
          pos5 = 'o'
        when 'deleted_split'
          pos5 = 's'
        when 'deleted_replaced'
          pos5 = 'x'
        end

        pos17 = if arc['level_of_detail'] == 'fully_established'
                  'n'
                else
                  'o'
                end

        pos12_16 = '00000'
      else
        pos5 = 'n'
        pos12_16 = '00000'
        pos17 = 'o'
      end

      xml.text "00000#{pos5}z  a22#{pos12_16}#{pos17}i 4500"
    end
  end

  def _controlfields(json, xml)
    aid = agent_id(json)

    xml.controlfield(tag: '001') do
      xml.text aid
    end

    if json['agent_record_controls']&.any?
      arc = json['agent_record_controls'].first
      xml.controlfield(tag: '003') do
        xml.text arc['maintenance_agency']
      end
    end

    if json['agent_maintenance_histories']&.any?
      most_recent = json['agent_maintenance_histories'].min { |a, b| b['event_date'] <=> a['event_date'] }
      xml.controlfield(tag: '005') do
        xml.text most_recent['event_date'].strftime('%Y%m%d%H%M%S.f')
      end
    end

    controlfield_008(json, xml)
  end

  # this field is mostly from agent_record_control record.
  def controlfield_008(json, xml)
    created_maint_events = json['agent_maintenance_histories'].select { |amh| amh['maintenance_event_type'] == 'created' }
    pos0_5 = if created_maint_events.any?
               created_maint_events.first['event_date'].strftime('%y%m%d')
             else
               '000000'
             end

    if json['agent_record_controls']&.any?
      arc = json['agent_record_controls'].first
      case arc['romanization']
      when 'int_std'
        pos_7 = 'a'
      when 'nat_std'
        pos_7 = 'b'
      when 'nl_assoc_std'
        pos_7 = 'c'
      when 'nl_bib_agency_std'
        pos_7 = 'd'
      when 'local_standard'
        pos_7 = 'e'
      when 'unknown_standard'
        pos_7 = 'f'
      when 'conv_rom_cat_agency'
        pos_7 = 'g'
      when 'not_applicable'
        pos_7 = 'n'
      end

      pos_8 = if arc['language']['eng']
                'e'
              elsif arc['language']['fre']
                'f'
              else
                '|'
              end

      case arc['government_agency_type']
      when 'ngo'
        pos_28 = ' '
      when 'sac'
        pos_28 = 'a'
      when 'multilocal'
        pos_28 = 'c'
      when 'fed'
        pos_28 = 'f'
      when 'int_gov'
        pos_28 = 'I'
      when 'local'
        pos_28 = 'l'
      when 'multistate'
        pos_28 = 'm'
      when 'undetermined'
        pos_28 = 'o'
      when 'provincial'
        pos_28 = 's'
      when 'unknown'
        pos_28 = 'u'
      when 'other'
        pos_28 = 'z'
      when 'natc'
        pos_28 = '|'
      end

      case arc['reference_evaluation']
      when 'tr_consistent'
        pos_29 = 'a'
      when 'tr_inconsistent'
        pos_29 = 'b'
      when 'not_applicable'
        pos_29 = 'n'
      when 'natc'
        pos_29 = '|'
      end

      case arc['name_type']
      when 'differentiated'
        pos_32 = 'a'
      when 'undifferentiated'
        pos_32 = 'b'
      when 'not_applicable'
        pos_32 = 'n'
      when 'natc'
        pos_32 = '|'
      end

      case arc['level_of_detail']
      when 'fully_established'
        pos_33 = 'a'
      when 'memorandum'
        pos_33 = 'b'
      when 'provisional'
        pos_33 = 'c'
      when 'preliminary'
        pos_33 = 'd'
      when 'not_applicable'
        pos_33 = 'n'
      when 'natc'
        pos_33 = '|'
      end

      case arc['modified_record']
      when 'not_modified'
        pos_38 = ' '
      when 'shortened'
        pos_38 = 's'
      when 'missing_characters'
        pos_38 = 'x'
      when 'natc'
        pos_38 = '|'
      end

      case arc['cataloging_source']
      when 'nat_bib_agency'
        pos_39 = ' '
      when 'ccp'
        pos_39 = 'c'
      when 'other'
        pos_39 = 'd'
      when 'unknown'
        pos_39 = 'u'
      when 'natc'
        pos_39 = '|'
      end
    else
      pos_7 = '|'
      pos_8 = '|'
      pos_28 = '|'
      pos_29 = '|'
      pos_32 = '|'
      pos_33 = '|'
      pos_38 = '|'
      pos_39 = '|'
    end

    xml.controlfield(tag: '008') do
      xml.text "#{pos0_5}n#{pos_7}#{pos_8}aznnnaabn          #{pos_28}#{pos_29} a#{pos_32}#{pos_33}    #{pos_38}#{pos_39}"
    end
  end

  def record_ids(json, xml)
    return unless json['agent_record_identifiers']&.any?

    identifiers = json['agent_record_identifiers']
    props = ['identifier_type']

    with_value(identifiers, props, 'loc') do |record|
      xml.datafield(tag: '010', ind1: ' ', ind2: ' ') do
        subf('a', record['record_identifier'], xml)
      end
      break # Field is Not-Repeatable
    end

    with_value(identifiers, props, 'lac') do |record|
      xml.datafield(tag: '016', ind1: '7', ind2: ' ') do
        subf('a', record['record_identifier'], xml)
        subf('2', record['source'], xml)
      end
    end

    without_values(identifiers, props, ['loc', 'lac', 'local']) do |record|
      xml.datafield(tag: '024', ind1: '7', ind2: ' ') do
        subf('a', record['record_identifier'], xml)
        subf('2', record['source'], xml)
      end
    end

    with_value(identifiers, props, 'local') do |record|
      xml.datafield(tag: '035', ind1: ' ', ind2: ' ') do
        subf('a', record['record_identifier'], xml)
        subf('2', record['source'], xml)
      end
    end
  end

  def record_control(json, xml)
    if json['agent_record_controls']&.any?
      arc = json['agent_record_controls'].first
      a_value = arc['maintenance_agency']
      b_value = arc['language']
      # TODO: d_value? but we don't store a modifying agency
    end

    if json['agent_conventions_declarations']&.any?
      acd = json['agent_conventions_declarations'].first
      e_value = acd['name_rule']
    end

    if a_value || b_value || e_value
      xml.datafield(tag: '040', ind1: ' ', ind2: ' ') do
        subf('a', a_value, xml)
        subf('b', b_value, xml)
        subf('e', e_value, xml)
      end
    end
  end

  def names(json, xml)
    # ANW-504: look for an agent marked primary first
    primary = nil
    primary = json['names'].select { |n| n['is_primary'] == true }.first

    # otherwise, simply grab the first one
    primary = json['names'].select { |n| n['authorized'] == true }.first unless primary
    not_primary = json['names'].select { |n| n['authorized'] == false }

    parallel_names = []
    json['names'].each do |n|
      parallel_names += n['parallel_names']
    end

    if agent_type(json) == :person
      names_person(primary, not_primary, parallel_names, xml)
    elsif agent_type(json) == :family
      names_family(primary, not_primary, parallel_names, xml)
    elsif agent_type(json) == :corp
      names_corporate_entity(primary, not_primary, parallel_names, xml)
    end
  end

  def name_formatter(parts, xml, omit_first_sub_prefix: false)
    primary_subfield = parts.shift
    subf(primary_subfield[:code], primary_subfield[:value], xml)

    return unless parts.any? # jump ship if we don't have more parts

    if parts.count == 1
      subf(parts.first[:code], "(#{parts.first[:value]})", xml)
    else
      prefix = omit_first_sub_prefix ? '' : '('
      sub_first = parts.shift
      sub_last  = parts.pop
      subf(sub_first[:code], "#{prefix}#{sub_first[:value]} : ", xml)
      parts.each { |p| subf(p[:code], "#{p[:value]} : ", xml) }
      subf(sub_last[:code], "#{sub_last[:value]})", xml)
    end
  end

  def names_person(primary, not_primary, parallel, xml)
    # the primary name gets the 100 tag
    if primary
      ind1 = primary['name_order'] == 'indirect' ? '1' : '0'
      xml.datafield(tag: '100', ind1: ind1, ind2: ' ') do
        person_name_subtags(primary, xml)
      end
    end

    # all other names and parallel names are put in 400 tags
    (not_primary + parallel).each do |n|
      ind1 = n['name_order'] == 'indirect' ? '1' : '0'
      xml.datafield(tag: '400', ind1: ind1, ind2: ' ') do
        person_name_subtags(n, xml)
      end
    end
  end

  def person_name_subtags(name, xml, related = false)
    related_sfs(name, xml) if related
    primary = name['rest_of_name'] ? "#{name['primary_name']}, #{name['rest_of_name']}" : name['primary_name']
    subf('a', primary, xml)
    subf('b', name['number'], xml)
    subf('c', name['title'], xml)
    subf('d', name['dates'], xml)
    subf('g', name['qualifier'], xml)
    subf('q', name['fuller_form'], xml)
  end

  def names_family(primary, not_primary, parallel, xml)
    # the primary name gets the 100 tag
    if primary
      xml.datafield(tag: '100', ind1: '3', ind2: ' ') do
        family_name_subtags(primary, xml)
      end
    end

    # all other names and parallel names are put in 400 tags
    (not_primary + parallel).each do |n|
      xml.datafield(tag: '400', ind1: '3', ind2: ' ') do
        family_name_subtags(n, xml)
      end
    end
  end

  def family_name_subtags(name, xml, related = false)
    related_sfs(name, xml) if related

    name_parts = [
      { code: 'c', value: name['location'] },
      { code: 'd', value: name['dates'] },
      { code: 'g', value: name['qualifier'] }
    ]
    name_parts = name_parts.delete_if { |p| p[:value].nil? || p[:value].empty? }
    # we have to do some futzing with subf 'a' if family type is available
    if name['family_type'] && name_parts.any?
      name_parts.unshift(
        { code: 'a', value: "#{name['prefix']} #{name['family_name']} (#{name['family_type']} : ".lstrip }
      )
      name_formatter(name_parts, xml, omit_first_sub_prefix: true)
    elsif name['family_type']
      name_parts.unshift(
        { code: 'a', value: "#{name['prefix']} #{name['family_name']} (#{name['family_type']})".lstrip }
      )
      name_formatter(name_parts, xml)
    else
      name_parts.unshift({ code: 'a', value: "#{name['prefix']} #{name['family_name']}".lstrip })
      name_formatter(name_parts, xml)
    end
  end

  def names_corporate_entity(primary, not_primary, parallel, xml)
    if primary
      if primary['conference_meeting'] == true
        xml.datafield(tag: '111', ind1: '2', ind2: ' ') do
          corporate_name_subtags(primary, xml)
        end
      else
        xml.datafield(tag: '110', ind1: '2', ind2: ' ') do
          corporate_name_subtags(primary, xml)
        end
      end
    end

    # all other names and parallel names are put in 400 tags
    (not_primary + parallel).each do |n|
      if n['conference_meeting'] == true
        xml.datafield(tag: '411', ind1: '2', ind2: ' ') do
          corporate_name_subtags(n, xml)
        end
      else
        xml.datafield(tag: '410', ind1: '2', ind2: ' ') do
          corporate_name_subtags(n, xml)
        end
      end
    end
  end

  def corporate_name_subtags(name, xml, related = false)
    related_sfs(name, xml) if related
    subf('a', name['primary_name'], xml)
    subf('b', name['subordinate_name_1'], xml)
    subf('q', name['subordinate_name_2'], xml)
    subf('n', name['number'], xml)
    subf('d', name['dates'], xml)
    subf('c', name['location'], xml)
    subf('g', name['qualifier'], xml)
  end

  def sub_w(name)
    case name['specific_relator'] || name['relator']
    when 'is_earlier_form_of'
      'a'
    when 'is_later_form_of'
      'b'
    when 'Acronym'
      'd'
    when 'Musical composition'
      'f'
    when 'Broader term'
      'g'
    when 'Narrower term'
      'h'
    else
      'r'
    end
  end

  def related_sfs(name, xml)
    specific = I18n.t("enumerations.specific_relator.#{name['specific_relator']}", :default => name['specific_relator'])
    relator = I18n.t("enumerations.#{name['rel_type']}_relator.#{name['relator']}", :default => name['relator'])
    subf('w', sub_w(name), xml)
    subf('i', specific || name['description'] || relator, xml)
  end

  def dates_of_existence(json, xml)
    json['dates_of_existence'].each do |doe|
      if agent_type(json) == :person
        begin_code = 'f'
        end_code = 'g'
      elsif agent_type(json) == :family || agent_type(json) == :corp
        begin_code = 's'
        end_code = 't'
      end
      xml.datafield(tag: '046', ind1: ' ', ind2: ' ') do
        dates(doe, begin_code, end_code, xml)
      end
    end
  end

  def dates(structured_date, begin_code, end_code, xml)
    if structured_date['date_type_structured'] == 'single'
      begin_date = structured_date['structured_date_single']['date_expression'] || structured_date['structured_date_single']['date_standardized']
      end_date = nil
    elsif structured_date['date_type_structured'] == 'range'
      begin_date = structured_date['structured_date_range']['begin_date_expression'] || structured_date['structured_date_range']['begin_date_standardized']
      end_date = structured_date['structured_date_range']['end_date_expression'] || structured_date['structured_date_range']['end_date_standardized']
    end
    subf(begin_code, begin_date, xml)
    subf(end_code, end_date, xml)
  end

  def subject_subrecord(record, title_subfield, xml)
    record['subjects'].each do |subject|
      subf(title_subfield, subject['_resolved']['title'], xml)
      # each subject gets the date info. from the first date subcrecord only
      dates(record['dates'].first, 's', 't', xml) if record['dates'].any?
      subf('0', subject['_resolved']['authority_id'], xml)
      subf('2', subject['_resolved']['source'], xml)
    end
  end

  def places(json, xml)
    json['agent_places'].each do |place|
      case place['place_role']
      when 'place_of_birth'
        subfield_code = 'a'
      when 'place_of_death'
        subfield_code = 'b'
      when 'assoc_country'
        subfield_code = 'c'
      when 'residence'
        subfield_code = 'e'
      when 'other_assoc'
        subfield_code = 'f'
      end
      xml.datafield(tag: '370', ind1: ' ', ind2: ' ') do
        subject_subrecord(place, subfield_code, xml)
      end
    end
  end

  def functions(json, xml)
    json['agent_functions'].each do |function|
      xml.datafield(tag: '372', ind1: ' ', ind2: ' ') do
        subject_subrecord(function, 'a', xml)
      end
    end
  end

  def topics(json, xml)
    json['agent_topics'].each do |topic|
      xml.datafield(tag: '372', ind1: ' ', ind2: ' ') do
        subject_subrecord(topic, 'a', xml)
      end
    end
  end

  def occupations(json, xml)
    json['agent_occupations'].each do |occupation|
      xml.datafield(tag: '374', ind1: ' ', ind2: ' ') do
        subject_subrecord(occupation, 'a', xml)
      end
    end
  end

  def gender(json, xml)
    json['agent_genders'].each do |gender|
      xml.datafield(tag: '375', ind1: ' ', ind2: ' ') do
        subf('a', gender['gender'], xml)
        dates(gender['dates'].first, 's', 't', xml) if gender['dates'].any?
      end
    end
  end

  def used_languages(json, xml)
    json['used_languages'].each do |lang|
      xml.datafield(tag: '377', ind1: ' ', ind2: '7') do
        subf('a', lang['language'], xml)
        subf('2', 'iso639-2b', xml)
      end
    end
  end

  def sources(json, xml)
    json['agent_sources'].each do |source|
      xml.datafield(tag: '670', ind1: ' ', ind2: ' ') do
        subf('a', source['source_entry'], xml)
        subf('b', source['descriptive_note'], xml)
        subf('u', source['file_uri'], xml)
      end
    end
  end

  def notes(json, xml)
    with_value(json['notes'], 'jsonmodel_type', 'note_bioghist') do |note|
      ind1 = agent_type(json) == :person || agent_type(json) == :family_name ? '0' : '1'
      xml.datafield(tag: '678', ind1: ind1, ind2: ' ') do
        with_value(note['subnotes'], 'jsonmodel_type', 'note_abstract') do |abstract|
          content = abstract.respond_to?(:key) ? abstract['content'].first : abstract.first['content'].first
          subf('a', clean_text(content), xml)
        end
        with_value(note['subnotes'], 'jsonmodel_type', 'note_text') do |text|
          content = text.respond_to?(:key) ? text['content'] : text.first['content']
          subf('b', clean_text(content), xml)
        end
      end
    end
  end

  # strips out carriage returns (...and maybe other things)
  def clean_text(text)
    text.gsub!(/\r\n/, '')
    text.gsub!(/\r/, '')
    text
  end

  def relationships(json, xml)
    json['related_agents'].each do |ra|
      agent = ra['_resolved']
      primary = agent['names'].select { |n| n['authorized'] == true }.first
      # smuggle in the relator info. for this relationship
      primary['rel_type'] = ra['jsonmodel_type']
      primary['relator'] = ra['relator']
      primary['specific_relator'] = ra['specific_relator']
      primary['description'] = ra['description']
      case agent['jsonmodel_type']
      when 'agent_person'
        ind1 = primary['name_order'] == 'indirect' ? '1' : '0'
        xml.datafield(tag: '500', ind1: ind1, ind2: ' ') do
          person_name_subtags(primary, xml, true)
        end
      when 'agent_family'
        xml.datafield(tag: '500', ind1: '3', ind2: ' ') do
          family_name_subtags(primary, xml, true)
        end
      when 'agent_corporate_entity'
        if primary['conference_meeting'] == true
          xml.datafield(tag: '511', ind1: '2', ind2: ' ') do
            corporate_name_subtags(primary, xml, true)
          end
        else
          xml.datafield(tag: '510', ind1: '2', ind2: ' ') do
            corporate_name_subtags(primary, xml, true)
          end
        end
      end
    end
  end

  # returns an ID for the agent, depending on what is defined.
  # IDs used are (in order)
  # Record IDs
  # Entity IDs
  # Name Auth ID
  # System URI
  def agent_id(json)
    names_with_auth_id = json['names'].select { |n| !n['authority_id'].nil? && !n['authority_id'].empty? }
    if json['agent_record_identifiers'].any?
      json['agent_record_identifiers'].first['record_identifier']
    elsif json['agent_identifiers'].any?
      json['agent_identifiers'].first['agent_identifier']
    elsif names_with_auth_id.any?
      names_with_auth_id.first['authority_id']
    else
      "#{AppConfig[:public_proxy_url]}#{json['uri']}"
    end
  end

  def agent_type(json)
    case json['jsonmodel_type']
    when 'agent_person'
      :person
    when 'agent_family'
      :family
    when 'agent_corporate_entity'
      :corp
    end
  end

  def subf(code, value, xml)
    return unless code && value

    xml.subfield(code: code) do
      xml.text value
    end
  end

  def with(collection, properties)
    Array(properties).each do |prop|
      collection.each do |coll|
        yield coll, prop if coll[prop]
      end
    end
  end

  def with_value(collection, properties, value)
    with(collection, properties) do |coll, prop|
      yield coll if coll[prop] == value
    end
  end

  def with_values(collection, properties, values)
    with(collection, properties) do |coll, prop|
      yield coll if values.include? coll[prop]
    end
  end

  def without_values(collection, properties, values)
    with(collection, properties) do |coll, prop|
      yield coll unless values.include? coll[prop]
    end
  end
end
