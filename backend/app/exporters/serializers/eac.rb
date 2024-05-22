# frozen_string_literal: true

class EACSerializer < ASpaceExport::Serializer
  serializer_for :eac

  def serialize(eac, _opts = {})
    builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      _eac(eac, xml)
    end
    builder.to_xml
  end

  private

  # wrapper around nokogiri that creates a node without empty attrs and nodes
  def create_node(xml, node_name, attrs, text)
    return if text.nil? || text.empty?

    xml.send(node_name, clean_attrs(attrs)) do
      xml.text text
    end
  end

  def filled_out?(values, mode = :some)
    if mode == :all
      values.reject { |v| v.to_s.empty? }.count == values.count
    else
      values.reject { |v| v.to_s.empty? }.any?
    end
  end

  def clean_attrs(attrs)
    attrs.reject { |_k, v| v.nil? }
  end

  # Wrapper for working with a list of records:
  # with(xml, json['agent_conventions_declarations']) do |cd|
  # with(xml, json['agent_places'], :places) do |place|
  def with(xml, records, node = nil)
    return unless records&.any?

    records.each do |record|
      if node
        xml.send(node) { yield record }
      else
        yield record
      end
    end
  end

  # Wrapper for a list of records inside a single context element
  # within(xml, :existDates, json['dates_of_existence']) do |date|
  def within(xml, node, records)
    return unless records&.any?

    xml.send(node) { records.each { |record| yield record } }
  end

  def _eac(obj, xml)
    json = obj.json
    xml.send('eac-cpf', { 'xmlns' => 'urn:isbn:1-931666-33-4',
                          'xmlns:html' => 'http://www.w3.org/1999/xhtml',
                          'xmlns:xlink' => 'http://www.w3.org/1999/xlink',
                          'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                          'xsi:schemaLocation' => 'urn:isbn:1-931666-33-4 https://eac.staatsbibliothek-berlin.de/schema/cpf.xsd',
                          'xml:lang' => 'eng' }) do
      _control(json, xml)
      _cpfdesc(json, xml, obj)
    end
  end

  def _control(json, xml)
    xml.control do
      # AGENT_RECORD_IDENTIFIERS
      with(xml, json['agent_record_identifiers']) do |ari|
        if ari['primary_identifier'] == true
          create_node(xml, 'recordId', {}, ari['record_identifier'])
        else
          attrs = { localType: ari['identifier_type'] }
          create_node(xml, 'otherRecordId', attrs, ari['record_identifier'])
        end
      end

      # AGENT_RECORD_CONTROLS
      with(xml, json['agent_record_controls']) do |arc|
        if arc['maintenance_status']
          value = I18n.t("enumerations.maintenance_status.#{arc['maintenance_status']}")

          value = case value
                  when "New"
                    "new"
                  when "Upgraded"
                    "revised"
                  when "Revised/Corrected"
                    "revised"
                  when "Derived"
                    "derived"
                  when "Deleted"
                    "deleted"
                  when "Cancelled/Obsolete"
                    "cancelled"
                  when "Deleted-Split"
                    "deletedSplit"
                  when "Deleted-Replaced"
                    "deletedReplaced"
                  when "Deleted-Merged"
                    "deletedMerged"
                  end

          create_node(
            xml,
            'maintenanceStatus',
            {},
            value
          )
        end
        create_node(xml, 'publicationStatus', {}, arc['publication_status'])

        if filled_out?([
                         arc['maintenance_agency'],
                         arc['agency_name'],
                         arc['maintenance_agency_note']
                       ])

          xml.maintenanceAgency do
            if AppConfig[:export_eac_agency_code]
              create_node(xml, 'agencyCode', {}, arc['maintenance_agency'])
            end
            create_node(xml, 'agencyName', {}, arc['agency_name'])
            _descriptive_note(arc['maintenance_agency_note'], xml)
          end
        end

        _language_and_script(
          xml, :languageDeclaration,
          arc['language'],
          arc['script'],
          [arc['language_note']]
        )

        break # only the first
      end

      # AGENT_CONVENTIONS_DECLARATIONS
      with(xml, json['agent_conventions_declarations']) do |cd|
        unless filled_out?([cd['name_rule'], cd['citation'], cd['descriptive_note']])
          next
        end

        xml.conventionDeclaration do
          xlink_attrs = {
            'xlink:href' => cd['file_uri'],
            'xlink:actuate' => cd['file_version_xlink_actuate_attribute'],
            'xlink:show' => cd['file_version_xlink_show_attribute'],
            'xlink:title' => cd['xlink_title_attribute'],
            'xlink:role' => cd['xlink_role_attribute'],
            'xlink:arcrole' => cd['xlink_arcrole_attribute'],
            'lastDateTimeVerified' => _format_date(cd['last_verified_date'])
          }

          create_node(xml, 'abbreviation', {}, cd['name_rule'])
          create_node(xml, 'citation', xlink_attrs, cd['citation'])
          _descriptive_note(cd['descriptive_note'], xml)
        end
      end

      # MAINTENANCE_HISTORY
      within(xml, :maintenanceHistory, json['agent_maintenance_histories']) do |mh|
        unless filled_out?([
                             mh['maintenance_event_type'],
                             mh['event_date'],
                             mh['maintenance_agent_type'],
                             mh['agent'],
                             mh['descriptive_note']
                           ])

          next
        end

        xml.maintenanceEvent do
          create_node(xml, 'eventType', {}, mh['maintenance_event_type'])

          if filled_out?([mh['event_date']], :all)
            xml.eventDateTime(standardDateTime: _format_date(mh['event_date']))
          end

          create_node(xml, 'agentType', {}, mh['maintenance_agent_type'])
          create_node(xml, 'agent', {}, mh['agent'])
          create_node(xml, 'eventDescription', {}, mh['descriptive_note'])
        end
      end

      # AGENT_SOURCES
      within(xml, :sources, json['agent_sources']) do |as|
        xlink_attrs = {
          'xlink:href' => as['file_uri'],
          'xlink:actuate' => as['file_version_xlink_actuate_attribute'],
          'xlink:show' => as['file_version_xlink_show_attribute'],
          'xlink:title' => as['xlink_title_attribute'],
          'xlink:role' => as['xlink_role_attribute'],
          'xlink:arcrole' => as['xlink_arcrole_attribute'],
          'lastDateTimeVerified' => _format_date(as['last_verified_date'])
        }

        next unless filled_out?([as['source_entry'], as['descriptive_note']])

        xml.source(clean_attrs(xlink_attrs)) do
          create_node(xml, 'sourceEntry', {}, as['source_entry'])
          _descriptive_note(as['descriptive_note'], xml)
        end
      end

      json['metadata_rights_declarations'].each do |mrd|
        xml.rightsDeclaration {
          if mrd["license"]
            xml.abbr (mrd["license"])
          end
          attributes = { href: mrd["file_uri"] }
          attributes[:arcrole] = mrd["xlink_arcrole_attribute"] if mrd["xlink_arcrole_attribute"]
          attributes[:role] = mrd["xlink_role_attribute"] if mrd["xlink_role_attribute"]
          xml.citation (attributes) {
            if mrd["license"]
              xml.text (I18n.t("enumerations.metadata_license.#{mrd['license']}", :default => mrd['license']))
            end
          }
          if mrd['descriptive_note']
            xml.descriptiveNote {
              xml.p (mrd["descriptive_note"]) if mrd["descriptive_note"]
            }
          end
        }
      end
    end # of xml.control
  end # of #_control

  def _cpfdesc(json, xml, obj)
    xml.cpfDescription do
      xml.identity do
        # AGENT_IDENTIFIERS
        with(xml, json['agent_identifiers']) do |ad|
          attrs = { localType: ad['identifier_type'] }
          create_node(xml, 'entityId', attrs, ad['entity_identifier'])
        end

        # ENTITY_TYPE
        entity_type = json['jsonmodel_type'].sub(/^agent_/, '').sub('corporate_entity', 'corporateBody')
        xml.entityType entity_type

        # NAMES
        with(xml, json['names']) do |name|
          # NAMES WITH PARALLEL
          if name['parallel_names']&.any?
            xml.nameEntryParallel do
              _build_name_entry(name, xml, json, obj, true)
              within(xml, :useDates, _date_map(name['use_dates'])) do |date|
                send(date[:date_method], date[:date], xml)
              end

              name['parallel_names'].each do |pname|
                _build_name_entry(pname, xml, json, obj, true)
              end
            end
          # NAMES NO PARALLEL
          else
            _build_name_entry(name, xml, json, obj)
          end
        end
      end # end of xml.identity

      xml.description do
        # DATES_OF_EXISTENCE
        within(xml, :existDates, json['dates_of_existence']) do |date|
          _date_map([date]).each do |d|
            send(d[:date_method], d[:date], xml)
          end
        end

        # LANGUAGES USED
        within(xml, :languagesUsed, json['used_languages']) do |lang|
          _language_and_script(
            xml, :languageUsed,
            lang['language'],
            lang['script'],
            _without_jsonmodel(lang['notes'], 'note_citation').map { |n| n['content'] }
          )
        end

        # PLACES
        with(xml, json['agent_places'], :places) do |place|
          _subject_subrecord(xml, :place, place)
        end

        # OCCUPATIONS
        with(xml, json['agent_occupations'], :occupations) do |occupation|
          _subject_subrecord(xml, :occupation, occupation)
        end

        # FUNCTIONS
        with(xml, json['agent_functions'], :functions) do |function|
          _subject_subrecord(xml, :function, function)
        end

        if json['agent_topics']&.any? || json['agent_genders']&.any?
          xml.localDescriptions(localType: 'archivesspace') do
            # TOPICS
            with(xml, json['agent_topics']) do |topic|
              _subject_subrecord(
                xml, :localDescription, topic, { localType: 'associatedSubject' }
              )
            end

            # GENDERS
            with(xml, json['agent_genders']) do |gender|
              next unless filled_out?([gender['gender']])

              xml.localDescription(localType: 'gender') do
                create_node(xml, 'term', {}, gender['gender'])
                _date_map(gender['dates']).each { |d| send(d[:date_method], d[:date], xml) }
                _descriptive_note(
                  _without_jsonmodel(gender['notes'], 'note_citation').map { |n| n['content'] }.join('\n'),
                  xml
                )
              end
            end
          end # close of xml.localDescriptions
        end # of if

        # NOTES
        # next unless n['publish']
        with(xml, _sorted_notes(json['notes'])) do |n|
          # next unless n['publish']
          xml.send(_note_elem_type(n['jsonmodel_type'])) do
            n['subnotes'].each do |sn|
              case sn['jsonmodel_type']
              when 'note_abstract'
                xml.abstract do
                  xml.text sn['content'].join('--')
                end
              when 'note_citation'
                atts = Hash[sn.fetch('xlink', {}).map { |x, v| ["xlink:#{x}", v] }.reject { |a| a[1].nil? }]
                xml.citation(atts) do
                  xml.text sn['content'].join('--')
                end

              when 'note_definedlist'
                xml.list(localType: 'defined') do
                  sn['items'].each do |item|
                    xml.item(localType: item['label']) do
                      xml.text item['value']
                    end
                  end
                end
              when 'note_orderedlist'
                xml.list(localType: 'ordered') do
                  sn['items'].each do |item|
                    xml.item(localType: sn['enumeration']) do
                      xml.text item
                    end
                  end
                end
              when 'note_chronology'
                atts = sn['title'] ? { localType: sn['title'] } : {}
                xml.chronList(atts) do
                  sn['items'].map { |i| i['events'].map { |e| [i['event_date'], e] } }.flatten(1).each do |pair|
                    date, event = pair
                    xml.chronItem do
                      xml.date({ standardDate: date }) { xml.text date } if date
                      xml.event event
                    end
                  end
                end
              when 'note_outline'
                xml.outline do
                  sn['levels'].each do |level|
                    _expand_level(level, xml)
                  end
                end
              when 'note_text'
                xml.p do
                  xml.text sn['content']
                end
              end
            end
          end
        end
      end # end of xml.description

      xml.relations do
        with(xml, json['agent_resources']) do |ar|
          next unless filled_out?([ar['linked_resource']])

          role = if ar['linked_agent_role'] == 'creator'
                   'creatorOf'
                 elsif ar['linked_agent_role'] == 'subject'
                   'subjectOf'
                 else
                   'other'
                 end

          xlink_attrs = {
            'resourceRelationType' => role,
            'xlink:href' => ar['file_uri'],
            'xlink:actuate' => ar['file_version_xlink_actuate_attribute'],
            'xlink:show' => ar['file_version_xlink_show_attribute'],
            'xlink:title' => ar['xlink_title_attribute'],
            'xlink:role' => ar['xlink_role_attribute'],
            'xlink:arcrole' => ar['xlink_arcrole_attribute'],
            'lastDateTimeVerified' => _format_date(ar['last_verified_date'])
          }

          xml.resourceRelation(clean_attrs(xlink_attrs)) do
            create_node(xml, 'relationEntry', {}, ar['linked_resource'])
            _date_map(ar['dates']).each do |d|
              send(d[:date_method], d[:date], xml)
            end
            with(xml, ar['places']) do |place|
              _place(
                xml,
                place['_resolved']['terms'].first['term'],
                place['_resolved']['place_role'],
                { vocabularySource: place['source'] }
              )
            end
          end
        end

        with(xml, json['related_agents']) do |ra|
          resolved = ra['_resolved']
          relator = ra['relator']

          name = case resolved['jsonmodel_type']
                 when 'agent_software'
                   resolved['display_name']['software_name']
                 when 'agent_family'
                   resolved['display_name']['family_name']
                 else
                   resolved['display_name']['primary_name']
                 end

          next unless filled_out?([name])

          relation_type = case relator
                          when 'is_identified_with'
                            'identity'
                          when 'is_hierarchical_with'
                            'hierarchical'
                          when 'is_parent_of', 'is_superior_of'
                            'hierarchical-parent'
                          when 'is_child_of', 'is_subordinate_to'
                            'hierarchical-child'
                          when 'is_temporal_with'
                            'temporal'
                          when 'is_earlier_form_of'
                            'temporal-earlier'
                          when 'is_later_form_of'
                            'temporal-later'
                          when 'is_related_with'
                            'family'
                          else
                            'associative'
                          end

          attrs = {
            :cpfRelationType => relation_type,
            'xlink:arcrole' => ra['relationship_uri'],
            'xlink:type' => 'simple',
            'xlink:href' => AppConfig[:public_proxy_url] + resolved['uri']
          }

          xml.cpfRelation(clean_attrs(attrs)) do
            xml.relationEntry name
            _descriptive_note(ra['description'], xml) if ra['description']
          end
        end

        obj.related_records.each do |record|
          role = record[:role] + 'Of'
          record = record[:record]
          atts = {
            :resourceRelationType => role,
            'xlink:type' => 'simple',
            'xlink:href' => "#{AppConfig[:public_proxy_url]}#{record['uri']}"
          }
          xml.resourceRelation(atts) do
            xml.relationEntry record['title']
          end
        end
      end # end of xml.relations

      # ALTERNATIVE SET
      within(xml, :alternativeSet, json['agent_alternate_sets']) do |aas|
        xlink_attrs = {
          'xlink:href' => aas['file_uri'],
          'xlink:actuate' => aas['file_version_xlink_actuate_attribute'],
          'xlink:show' => aas['file_version_xlink_show_attribute'],
          'xlink:title' => aas['xlink_title_attribute'],
          'xlink:role' => aas['xlink_role_attribute'],
          'xlink:arcrole' => aas['xlink_arcrole_attribute'],
          'lastDateTimeVerified' => _format_date(aas['last_verified_date'])
        }

        next unless filled_out?([aas['set_component'], aas['descriptive_note']])

        xml.setComponent(clean_attrs(xlink_attrs)) do
          create_node(xml, 'componentEntry', {}, aas['set_component'])
          _descriptive_note(aas['descriptive_note'], xml)
        end
      end
    end # end of xml.cpfDescription
  end

  # builds a date node when there is an expression but no standard dates
  def _build_date_single(date, xml)
    attrs = { localType: date['date_label'] }
    create_node(xml, 'date', attrs, date['structured_date_single']['date_expression'])
  end

  # builds a date node when standardized dates are defined.
  # if there is an expression, it will be used for the inner text. Otherwise, the standardized date will be used.
  def _build_date_single_std(date, xml)
    expression = date['structured_date_single']['date_expression']
    standardized = date['structured_date_single']['date_standardized']

    inner_text = expression ? expression : standardized

    std_attr = case date['structured_date_single']['date_standardized_type']
               when 'standard'
                 :standardDate
               when 'not_before'
                 :notBefore
               when 'not_after'
                 :notAfter
               end

    attrs = { localType: date['date_label'] }
    attrs[std_attr] = standardized

    create_node(xml, 'date', attrs, inner_text)
  end

  def _build_date_range(date, xml)
    xml.dateRange(localType: date['date_label']) do
      begin_attrs = { standardDate: date['structured_date_range']['begin_date_standardized'] }
      end_attrs = { standardDate: date['structured_date_range']['end_date_standardized'] }
      create_node(xml, 'fromDate', begin_attrs, date['structured_date_range']['begin_date_expression'])
      create_node(xml, 'toDate', end_attrs, date['structured_date_range']['end_date_expression'])
    end
  end

  def _build_date_range_std(date, xml)
    begin_expression = date['structured_date_range']['begin_date_expression']
    begin_standardized = date['structured_date_range']['begin_date_standardized']

    end_expression = date['structured_date_range']['end_date_expression']
    end_standardized = date['structured_date_range']['end_date_standardized']

    begin_inner_text = begin_expression ? begin_expression : begin_standardized
    end_inner_text = end_expression ? end_expression : end_standardized

    begin_std_attr = case date['structured_date_range']['begin_date_standardized_type']
                     when 'standard'
                       :standardDate
                     when 'not_before'
                       :notBefore
                     when 'not_after'
                       :notAfter
                     end

    end_std_attr = case date['structured_date_range']['end_date_standardized_type']
                   when 'standard'
                     :standardDate
                   when 'not_before'
                     :notBefore
                   when 'not_after'
                     :notAfter
                   end

    begin_attrs = {}
    begin_attrs[begin_std_attr] = begin_standardized

    end_attrs = {}
    end_attrs[end_std_attr] = end_standardized

    xml.dateRange(localType: date['date_label']) do
      create_node(xml, 'fromDate', begin_attrs, begin_inner_text)
      create_node(xml, 'toDate', end_attrs, end_inner_text)
    end
  end

  def _build_name_entry(name, xml, _json, obj, parallel = false)
    attrs = {
      'xml:lang' => name['language'],
      'scriptCode' => name['script'],
      'transliteration' => name['transliteration']
    }
    xml.nameEntry(clean_attrs(attrs)) do
      obj.name_part_fields.each do |field, localType|
        localType = localType.nil? ? field : localType
        next unless name[field]

        part_attrs = { localType: localType }
        create_node(xml, 'part', part_attrs, name[field])
      end

      unless parallel
        within(xml, :useDates, _date_map(name['use_dates'])) do |date|
          send(date[:date_method], date[:date], xml)
        end
      end

      if parallel && name['is_display_name'] && name['source']
        create_node(xml, 'preferredForm', {}, name['source'])
      end

      if name['authorized']
        create_node(xml, 'authorizedForm', {}, name['source'])
      else
        create_node(xml, 'alternativeForm', {}, name['source'])
      end
    end
  end

  def _date_map(dates)
    return [] unless dates

    dates.map do |date|
      date_method = _date_processor(date)

      # date_method will be nil if both expression and standardized_dates are missing
      next unless date_method

      { date_method: date_method, date: date }
    end.compact
  end

  def _date_processor(date)
    if date['date_type_structured'] == 'single'
      expression   = date['structured_date_single']['date_expression']
      standardized = date['structured_date_single']['date_standardized']

      if expression && !standardized
        date_method  = :_build_date_single
      elsif standardized || expression
        date_method  = :_build_date_single_std
      else
        date_method  = nil
      end

    else
      expression   = date['structured_date_range']['begin_date_expression'] || date['structured_date_range']['end_date_expression']

      standardized = date['structured_date_range']['begin_date_standardized'] || date['structured_date_range']['end_date_standardized']

      if expression && !standardized
        date_method  = :_build_date_range
      elsif standardized || expression
        date_method  = :_build_date_range_std
      else
        date_method  = nil
      end
    end

    date_method
  end

  def _descriptive_note(note, xml)
    return unless note && !note.empty?

    # nokogiri builder special tag for 'p'
    xml.descriptiveNote { create_node(xml, 'p_', {}, note) }
  end

  def _expand_level(level, xml)
    xml.level do
      level['items'].each do |item|
        if item.is_a?(String)
          xml.item item
        else
          _expand_level(item, xml)
        end
      end
    end
  end

  # convert: "2020-11-24 00:00:00 UTC" => "2020-11-24T00:00:00+00:00"
  def _format_date(date)
    return unless date

    DateTime.parse(date.to_s).iso8601
  end

  def _language_and_script(xml, node, language, script, notes = [])
    return unless language || script || notes.any?

    lang_t = I18n.t("enumerations.language_iso639_2.#{language}")
    lang_attrs = { 'languageCode' => language }
    script_t = I18n.t("enumerations.script_iso15924.#{script}")
    script_attrs = { 'scriptCode' => script }
    xml.send(node) do
      create_node(xml, 'language', lang_attrs, lang_t) if language
      create_node(xml, 'script', script_attrs, script_t) if script
      _descriptive_note(notes.compact.join("\n"), xml)
    end
  end

  def _note_elem_type(type)
    case type
    when 'note_bioghist'
      :biogHist
    when 'note_general_context'
      :generalContext
    when 'note_mandate'
      :mandate
    when 'note_legal_status'
      :legalStatus
    when 'note_structure_or_genealogy'
      :structureOrGenealogy
    end
  end

  # notes.sort_by { |n| _note_order(n['jsonmodel_type']) }
  def _note_order(type)
    case type
    when 'note_general_context'
      1
    when 'note_bioghist'
      2
    when 'note_mandate'
      3
    when 'note_legal_status'
      4
    when 'note_structure_or_genealogy'
      5
    else
      100
    end
  end

  def _place(xml, term, role, attrs = {})
    create_node(xml, 'placeRole', {}, role)
    create_node(xml, 'placeEntry', attrs, term)
  end

  def _sorted_notes(notes)
    notes&.sort_by { |n| _note_order(n['jsonmodel_type']) }
  end

  def _subject(xml, term)
    create_node(xml, 'term', {}, term)
  end

  def _subject_subrecord(xml, node, record, attributes = {})
    with(xml, record['subjects']) do |subject|
      subject = subject['_resolved']
      # SUBJECT
      xml.send(node, attributes) do
        if record['jsonmodel_type'] == 'agent_place'
          role = record['place_role'] ? I18n.t("enumerations.place_role.#{record['place_role']}") : nil
          _place(
            xml,
            subject['terms'].first['term'],
            role,
            { vocabularySource: subject['source'] }
          )
        else
          _subject(xml, subject['terms'].first['term'])
        end
        # DATES
        _date_map(record['dates']).each { |d| send(d[:date_method], d[:date], xml) }
        # NOTES
        _descriptive_note(
          _without_jsonmodel(record['notes'], 'note_citation').map { |n| n['content'] }.join('\n'),
          xml
        )
        # PLACES
        with(xml, record['places']) do |place|
          _place(
            xml,
            place['_resolved']['terms'].first['term'],
            place['_resolved']['place_role'],
            { vocabularySource: place['source'] }
          )
        end
      end
    end
  end

  def _without_jsonmodel(records, type)
    records.reject { |n| n['jsonmodel_type'] == type }
  end
end
