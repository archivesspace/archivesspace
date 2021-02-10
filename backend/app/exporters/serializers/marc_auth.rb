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

  # wrapper around nokogiri that creates a node without empty attrs and nodes
  # def create_node(xml, node_name, attrs, text)
  #   unless text.nil? || text.empty?
  #     attrs = attrs.reject {|k, v| v.nil? }
  #     xml.send(node_name, attrs) {
  #       xml.text text
  #     }
  #   end
  # end

  # def filled_out?(values, mode = :some)
  #   if mode == :all
  #     values.inject {|memo, v| memo && (!v.nil? && !v.empty?) }
  #   else mode == :some
  #     values.inject {|memo, v| memo || (!v.nil? && !v.empty?) }
  #   end
  # end

  # def clean_attrs(attrs)
  #   attrs.reject {|k, v| v.nil? }
  # end

  def _marc(obj, xml)
    json = obj.json
    xml.collection(
      'xmlns' => 'http://www.loc.gov/MARC21/slim',
      'xmlns:marc' => 'http://www.loc.gov/MARC21/slim',
      'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
      'xsi:schemaLocation' => 'http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd'
    ) do
      xml.record do
        _leader(json, xml)
        _controlfields(json, xml)
        ids(json, xml)
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

  def ids(json, xml)
    if json['agent_record_identifiers']&.any?
      loc_ids = json['agent_record_identifiers'].select { |ari| ari['identifier_type'] == 'loc' }
      lac_ids = json['agent_record_identifiers'].select { |ari| ari['identifier_type'] == 'lac' }
      local_ids = json['agent_record_identifiers'].select { |ari| ari['identifier_type'] == 'local' }
      other_ids = json['agent_record_identifiers'].reject { |ari| ['loc', 'lac', 'local'].include?(ari['identifier_type']) }

      if loc_ids.any?
        xml.datafield(tag: '010', ind1: ' ', ind2: ' ') do
          xml.subfield(code: 'a') do
            xml.text loc_ids.first['record_identifier']
          end
        end
      end

      if lac_ids.any?
        xml.datafield(tag: '016', ind1: '7', ind2: ' ') do
          xml.subfield(code: 'a') do
            xml.text lac_ids.first['record_identifier']
          end

          xml.subfield(code: '2') do
            xml.text lac_ids.first['source']
          end
        end
      end

      if other_ids.any?
        xml.datafield(tag: '024', ind1: '7', ind2: ' ') do
          xml.subfield(code: 'a') do
            xml.text other_ids.first['record_identifier']
          end

          xml.subfield(code: '2') do
            xml.text other_ids.first['source']
          end
        end
      end

      if local_ids.any?
        xml.datafield(tag: '035', ind1: ' ', ind2: ' ') do
          xml.subfield(code: 'a') do
            xml.text local_ids.first['record_identifier']
          end

          xml.subfield(code: '2') do
            xml.text local_ids.first['source']
          end
        end
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
        if a_value
          xml.subfield(code: 'a') do
            xml.text a_value
          end
        end

        if b_value
          xml.subfield(code: 'b') do
            xml.text b_value
          end
        end

        if e_value
          xml.subfield(code: 'e') do
            xml.text e_value
          end
        end
      end
    end
  end

  def names(json, xml)
    primary = json['names'].select { |n| n['authorized'] == true }.first
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

  def names_person(primary, not_primary, parallel, xml)
    # the primary name gets the 100 tag
    if primary
      ind1 = primary['name_order'] == 'indirect' ? '1' : '0'
      xml.datafield(tag: '100', ind1: ind1, ind2: ' ') do
        person_name_subtags(primary, xml)
      end
    end

    # all other names and parallel names are put in 400 tags
    not_primary.each do |n|
      ind1 = n['name_order'] == 'indirect' ? '1' : '0'
      xml.datafield(tag: '400', ind1: ind1, ind2: ' ') do
        person_name_subtags(n, xml)
      end
    end

    parallel.each do |n|
      ind1 = n['name_order'] == 'indirect' ? '1' : '0'
      xml.datafield(tag: '400', ind1: ind1, ind2: ' ') do
        person_name_subtags(n, xml)
      end
    end
  end

  def person_name_subtags(name, xml)
    xml.subfield(code: 'a') do
      if name['rest_of_name']
        xml.text name['primary_name'] + ',' + name['rest_of_name']
      else
        xml.text name['primary_name']
      end
    end

    if name['number']
      xml.subfield(code: 'b') do
        xml.text name['number']
      end
    end

    if name['title']
      xml.subfield(code: 'c') do
        xml.text name['title']
      end
    end

    if name['dates']
      xml.subfield(code: 'd') do
        xml.text name['dates']
      end
    end

    if name['qualifier']
      xml.subfield(code: 'g') do
        xml.text name['qualifier']
      end
    end

    if name['fuller_form']
      xml.subfield(code: 'q') do
        xml.text name['fuller_form']
      end
    end
  end

  def names_family(primary, not_primary, parallel, xml)
    # the primary name gets the 100 tag
    if primary
      xml.datafield(tag: '100', ind1: '3', ind2: ' ') do
        family_name_subtags(primary, xml)
      end
    end

    # all other names and parallel names are put in 400 tags
    not_primary.each do |n|
      xml.datafield(tag: '400', ind1: '3', ind2: ' ') do
        family_name_subtags(n, xml)
      end
    end

    parallel.each do |n|
      xml.datafield(tag: '400', ind1: '3', ind2: ' ') do
        family_name_subtags(n, xml)
      end
    end
  end

  def family_name_subtags(name, xml)
    xml.subfield(code: 'a') do
      xml.text name['family_name']
    end

    if name['qualifier']
      xml.subfield(code: 'b') do
        xml.text name['qualifier']
      end

      xml.subfield(code: 'c') do
        xml.text name['qualifier']
      end

      xml.subfield(code: 'g') do
        xml.text name['qualifier']
      end
    end

    if name['dates']
      xml.subfield(code: 'd') do
        xml.text name['dates']
      end
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
    not_primary.each do |n|
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

    parallel.each do |n|
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

  def corporate_name_subtags(name, xml)
    xml.subfield(code: 'a') do
      xml.text name['primary_name']
    end

    if name['subordinate_name_1']
      xml.subfield(code: 'b') do
        xml.text name['subordinate_name_1']
      end
    end

    if name['subordinate_name_2']
      xml.subfield(code: 'q') do
        xml.text name['subordinate_name_2']
      end
    end

    if name['location']
      xml.subfield(code: 'c') do
        xml.text name['location']
      end
    end

    if name['dates']
      xml.subfield(code: 'd') do
        xml.text name['dates']
      end
    end

    if name['number']
      xml.subfield(code: 'n') do
        xml.text name['number']
      end
    end

    if name['qualifier']
      xml.subfield(code: 'g') do
        xml.text name['qualifier']
      end
    end
  end

  def dates_of_existence(json, xml)
    if json['dates_of_existence']&.any?
      json['dates_of_existence'].each do |doe|
        if agent_type(json) == :person
          begin_code = 'f'
          end_code = 'g'
        elsif agent_type(json) == :family || agent_type(json) == :corp
          begin_code = 's'
          end_code = 't'
        end

        xml.datafield(tag: '046', ind1: ' ', ind2: ' ') do
          dates_standardized(doe, begin_code, end_code, xml)
        end
      end
    end
  end

  def dates(structured_date, begin_code, end_code, xml)
    if structured_date['date_type_structured'] == 'single'
      begin_date = structured_date['structured_date_single']['date_expression'] || structured_date['structured_date_single']['date_standardized']
    elsif structured_date['date_type_structured'] == 'range'
      begin_date = structured_date['structured_date_range']['begin_date_expression'] || structured_date['structured_date_range']['begin_date_standardized']
      end_date = structured_date['structured_date_range']['end_date_expression'] || structured_date['structured_date_range']['end_date_standardized']
    end

    xml.subfield(code: begin_code) do
      xml.text begin_date
    end

    if end_date
      xml.subfield(code: end_code) do
        xml.text end_date
      end
    end
  end

  # similar to above method, but only outputs standardized dates
  def dates_standardized(structured_date, begin_code, end_code, xml)
    if structured_date['date_type_structured'] == 'single'
      begin_date = structured_date['structured_date_single']['date_standardized']
    elsif structured_date['date_type_structured'] == 'range'
      begin_date = structured_date['structured_date_range']['begin_date_standardized']
      end_date = structured_date['structured_date_range']['end_date_standardized']
    end

    if begin_date
      xml.subfield(code: begin_code) do
        xml.text begin_date
      end
    end

    if end_date
      xml.subfield(code: end_code) do
        xml.text end_date
      end
    end
  end

  def places(json, xml)
    if json['agent_places'].any?
      json['agent_places'].each do |place|
        xml.datafield(tag: '370', ind1: ' ', ind2: ' ') do
          case place['place_role']
          when 'place_of_birth'
            subfield_code = 'a'
          when 'place_of_death'
            subfield_code = 'b'
          when 'assoc_country'
            subfield_code = 'a'
          when 'residence'
            subfield_code = 'd'
          when 'other_assoc'
            subfield_code = 'f'
          end

          xml.subfield(code: subfield_code) do
            xml.text place['subjects'].first['_resolved']['title']
          end

          dates(place['dates'].first, 's', 't', xml) if place['dates'].any?

          if place['subjects'].first['_resolved']['authority_id']
            xml.subfield(code: '2') do
              xml.text place['subjects'].first['_resolved']['authority_id']
            end
          end
        end
      end
    end
  end

  def occupations(json, xml)
    if json['agent_occupations'].any?
      json['agent_occupations'].each do |occupation|
        xml.datafield(tag: '374', ind1: ' ', ind2: ' ') do
          xml.subfield(code: 'a') do
            xml.text occupation['subjects'].first['_resolved']['title']
          end

          if occupation['dates'].any?
            dates(occupation['dates'].first, 's', 't', xml)
          end

          if occupation['subjects'].first['_resolved']['authority_id']
            xml.subfield(code: '2') do
              xml.text occupation['subjects'].first['_resolved']['authority_id']
            end
          end
        end
      end
    end
  end

  def topics(json, xml)
    if json['agent_topics'].any?
      json['agent_topics'].each do |topic|
        xml.datafield(tag: '372', ind1: ' ', ind2: ' ') do
          xml.subfield(code: 'a') do
            xml.text topic['subjects'].first['_resolved']['title']
          end

          dates(topic['dates'].first, 's', 't', xml) if topic['dates'].any?

          if topic['subjects'].first['_resolved']['authority_id']
            xml.subfield(code: '2') do
              xml.text topic['subjects'].first['_resolved']['authority_id']
            end
          end
        end
      end
    end
  end

  def functions(json, xml)
    if json['agent_functions'].any?
      json['agent_functions'].each do |function|
        xml.datafield(tag: '372', ind1: ' ', ind2: ' ') do
          xml.subfield(code: 'a') do
            xml.text function['subjects'].first['_resolved']['title']
          end

          if function['dates'].any?
            dates(function['dates'].first, 's', 't', xml)
          end

          if function['subjects'].first['_resolved']['authority_id']
            xml.subfield(code: '2') do
              xml.text function['subjects'].first['_resolved']['authority_id']
            end
          end
        end
      end
    end
  end

  def gender(json, xml)
    if json['agent_genders'].any?
      json['agent_genders'].each do |gender|
        xml.datafield(tag: '375', ind1: ' ', ind2: ' ') do
          xml.subfield(code: 'a') do
            xml.text gender['gender']
          end

          dates(gender['dates'].first, 's', 't', xml) if gender['dates'].any?
        end
      end
    end
  end

  def used_languages(json, xml)
    if json['used_languages'].any?
      json['used_languages'].each do |lang|
        xml.datafield(tag: '377', ind1: ' ', ind2: '7') do
          xml.subfield(code: 'a') do
            xml.text lang['language']
          end

          xml.subfield(code: '2') do
            xml.text 'iso639-2b'
          end
        end
      end
    end
  end

  def sources(json, xml)
    if json['agent_sources'].any?
      json['agent_sources'].each do |source|
        xml.datafield(tag: '670', ind1: ' ', ind2: ' ') do
          if source['source_entry']
            xml.subfield(code: 'a') do
              xml.text source['source_entry']
            end
          end

          if source['descriptive_note']
            xml.subfield(code: 'b') do
              xml.text source['descriptive_note']
            end
          end

          if source['file_uri']
            xml.subfield(code: 'u') do
              xml.text source['file_uri']
            end
          end
        end
      end
    end
  end

  def notes(json, xml)
    if json['notes'].any?
      bioghist_notes = json['notes'].select { |n| n['jsonmodel_type'] == 'note_bioghist' }

      bioghist_notes.each do |note|
        abstract = note['subnotes'].select { |n| n['jsonmodel_type'] == 'note_abstract' }
        text = note['subnotes'].select { |n| n['jsonmodel_type'] == 'note_text' }

        ind1 = if agent_type(json) == :person || agent_type(json) == :family_name
                 '0'
               else
                 '1'
               end

        xml.datafield(tag: '678', ind1: ind1, ind2: ' ') do
          if abstract.any?
            xml.subfield(code: 'a') do
              content = clean_text(abstract.first['content'].first)
              xml.text content
            end
          end

          if text.any?
            xml.subfield(code: 'b') do
              content = clean_text(text.first['content'])
              xml.text content
            end
          end
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
    if json['related_agents']&.any?
      json['related_agents'].each do |ra|
        agent = ra['_resolved']

        case agent['jsonmodel_type']
        when 'agent_person'
          primary = agent['names'].select { |n| n['authorized'] == true }.first
          ind1 = primary['name_order'] == 'indirect' ? '1' : '0'
          xml.datafield(tag: '500', ind1: ind1, ind2: ' ') do
            person_name_subtags(primary, xml)
          end

        when 'agent_family'
          primary = agent['names'].select { |n| n['authorized'] == true }.first

          xml.datafield(tag: '500', ind1: '3', ind2: ' ') do
            family_name_subtags(primary, xml)
          end

        when 'agent_corporate_entity'
          primary = agent['names'].select { |n| n['authorized'] == true }.first

          if primary['conference_meeting'] == true
            xml.datafield(tag: '511', ind1: '2', ind2: ' ') do
              corporate_name_subtags(primary, xml)
            end
          else
            xml.datafield(tag: '510', ind1: '2', ind2: ' ') do
              corporate_name_subtags(primary, xml)
            end
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
end
