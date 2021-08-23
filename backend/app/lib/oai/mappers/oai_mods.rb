require_relative 'oai_utils'

class OAIMODSMapper

  def map_oai_record(record)
    jsonmodel = record.jsonmodel_record
    result = Nokogiri::XML::Builder.new do |xml|

      xml.mods('xmlns' => 'http://www.loc.gov/mods/v3',
               'xmlns:xlink' => 'http://www.w3.org/1999/xlink',
               'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
               'xsi:schemaLocation' => 'http://www.loc.gov/mods/v3 https://www.loc.gov/standards/mods/v3/mods-3-6.xsd') do

        # Repo name -> location/physicalLocation
        xml.location {
          xml.physicalLocation(jsonmodel['repository']['_resolved']['name'])
        }

        # Identifier -> identifier
        # TODO: Reuse after implementing 'off' switch for ARK
        merged_identifier = if jsonmodel['jsonmodel_type'] == 'archival_object'
                              ([jsonmodel['component_id']] + jsonmodel['ancestors'].map {|a| a['_resolved']['component_id']}).compact.reverse.join(".")
                            else
                              (0..3).map {|id| jsonmodel["id_#{id}"]}.compact.join('.')
                            end

        if AppConfig[:arks_enabled]
          ark_url = jsonmodel.dig('ark_name', 'current')

          unless ark_url.nil? || ark_url.empty?
            xml.identifier(ark_url)
          end
        end

        # Creator -> name/namePart
        Array(jsonmodel['linked_agents']).each do |link|
          next unless link['_resolved']['publish']

          if link['role'] == 'creator'
            xml.name { xml.namePart(link['_resolved']['title']) }
          end
        end

        # Title -> titleInfo/title
        xml.titleinfo {
          xml.title(OAIUtils.display_string(jsonmodel))
        }

        # Dates -> originInfo/dateCreated
        Array(jsonmodel['dates']).each do |date|
          next unless date['label'] == 'creation'

          if date['begin'] || date['end']
            xml.originInfo {
              xml.dateCreated({'encoding' => 'iso8601'},
                              [date['begin'], date['end']].compact.join('/'))
            }
          elsif date['expression']
            xml.originInfo { xml.dateCreated(date['expression']) }
          end
        end

        # Extent -> physicalDescription/extent
        Array(jsonmodel['extents']).each do |extent|
          extent_str = [extent['number'] + ' ' + I18n.t('enumerations.extent_extent_type.' + extent['extent_type'], :default => extent['extent_type']), extent['container_summary']].compact.join('; ')
          xml.physicalDescription { xml.extent(extent_str) }
        end

        # Dimensions notes -> physicalDescription/extent
        Array(jsonmodel['notes'])
          .select {|note| ['dimensions'].include?(note['type'])}
          .each do |note|
          OAIUtils.extract_published_note_content(note).each do |content|
            xml.physicalDescription { xml.extent(content) }
          end
        end

        # Languages -> language/languageTerm
        if (lang_materials = Array(jsonmodel['lang_materials']))
          language_vals = lang_materials.map {|l| l['language_and_script']}.compact
          if !language_vals.empty?
            language_vals.each do |l|
              xml.language {
                xml.languageTerm({'authority' => 'iso639-2b', 'type' => 'text'}, I18n.t("enumerations.language_iso639_2." + l['language']))
                xml.languageTerm({'authority' => 'iso639-2b', 'type' => 'code'}, l['language'])
                if l['script']
                  xml.scriptTerm({'authority' => 'iso15924', 'type' => 'text'}, I18n.t("enumerations.script_iso15924." + l['script']))
                  xml.scriptTerm({'authority' => 'iso15924', 'type' => 'code'}, l['script'])
                end
              }
            end
          end
          language_notes = lang_materials.map {|l| l['notes']}.compact.reject {|e| e == [] }.flatten
          if !language_notes.empty?
            language_notes.each do |note|
              OAIUtils.extract_published_note_content(note).each do |content|
                xml.note({'type' => 'language'}, content)
              end
            end
          end
        end

        # Abstract note -> abstract
        Array(jsonmodel['notes'])
          .each do |note|
          OAIUtils.extract_published_note_content(note).each do |content|
            case note['type']
            when 'bioghist'
              xml.note({'type' => 'biographical'}, content)
            when 'scopecontent', 'abstract'
              xml.abstract(content)
            when 'odd'
              xml.note(content)
            when 'arrangement'
              xml.note({'type' => 'organization'}, content)
            when 'altformavail'
              xml.note({'type' => 'additionalform'}, content)
            when 'accessrestrict'
              xml.accessCondition({'type' => 'restrictionOnAccess'}, content)
            when 'userestrict'
              xml.accessCondition({'type' => 'useAndReproduction'}, content)
            when 'accruals'
              xml.note({'type' => 'accrual method'}, content)
            when 'acqinfo'
              xml.note({'type' => 'acquisition'}, content)
            when 'appraisal'
              xml.note({'type' => 'action'}, content)
            when 'bibliography'
              xml.note({'type' => 'citation'}, content)
            when 'custodhist'
              xml.note({'type' => 'ownership'}, content)
            when 'originalsloc'
              xml.note({'type' => 'originallocation'}, content)
            when 'fileplan'
              xml.note({'type' => 'fileplan'}, content)
            when 'otherfindaid'
              xml.note({'type' => 'otherfindaid'}, content)
            when 'phystech'
              xml.note({'type' => 'systemdetails'}, content)
            when 'prefercite'
              xml.note({'type' => 'preferredcitation'}, content)
            when 'processinfo'
              xml.note({'type' => 'action'}, content)
            when 'relatedmaterial'
              xml.note({'type' => 'relatedmaterial'}, content)
            when 'separatedmaterial'
              xml.note({'type' => 'separatedmaterial'}, content)
            end
          end
        end

        # Subjects
        Array(jsonmodel['subjects']).each do |subject|
          term_types = subject['_resolved']['terms'].map {|term| term['term_type']}

          if term_types.include?('topical')
            xml.subject { xml.topic(subject['_resolved']['title']) }
          elsif term_types.include?('geographic')
            xml.subject { xml.geographic(subject['_resolved']['title']) }
          elsif term_types.include?('genre_form')
            xml.subject { xml.genre(subject['_resolved']['title']) }
          else
            xml.subject(subject['_resolved']['title'])
          end
        end


        # Agents as subject
        Array(jsonmodel['linked_agents']).each do |link|
          next unless link['role'] == 'subject'
          next unless link['_resolved']['publish']

          case link['_resolved']['agent_type']
          when 'agent_person', 'agent_family'
            xml.subject { xml.name({'type' => 'personal'}, link['_resolved']['title']) }
          when 'agent_corporate_entity'
            xml.subject { xml.name({'type' => 'corporate'}, link['_resolved']['title']) }
          end
        end

        # Originating Collection
        if jsonmodel['jsonmodel_type'] == 'archival_object'
          resource_id_str = (0..3).map {|i| jsonmodel['resource']['_resolved']["id_#{i}"]}.compact.join(".")
          resource_str = [jsonmodel['resource']['_resolved']['title'], resource_id_str].join(', ')

          xml.relatedItem({'type' => 'host'}, resource_str)
        end
      end
    end

    result.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::NO_DECLARATION)
  end

end
