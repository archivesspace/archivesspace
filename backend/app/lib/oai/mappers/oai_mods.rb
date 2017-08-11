require 'uri'
require_relative 'oai_utils'

class OAIMODSMapper

  def map_oai_record(record)
    jsonmodel = record.jsonmodel_record
    result = Nokogiri::XML::Builder.new do |xml|

      xml.mods('xmlns' => 'http://www.loc.gov/mods/v3',
               'xmlns:xlink' => 'http://www.w3.org/1999/xlink',
               'xsi:schemaLocation' => 'http://www.loc.gov/mods/v3 https://www.loc.gov/standards/mods/v3/mods-3-6.xsd') do

        # Repo name -> location/physicalLocation
        xml.location {
          xml.physicalLocation(jsonmodel['repository']['_resolved']['name'])
        }

        # Identifier -> identifier
        merged_identifier = if jsonmodel['jsonmodel_type'] == 'archival_object'
                              ([jsonmodel['component_id']] + jsonmodel['ancestors'].map {|a| a['_resolved']['component_id']}).compact.reverse.join(".")
                            else
                              (0..3).map {|id| jsonmodel["id_#{id}"]}.compact.join('.')
                            end

        unless merged_identifier.empty?
          xml.identifier(merged_identifier)
        end

        # Creator -> name/namePart
        Array(jsonmodel['linked_agents']).each do |link|
          next unless link['_resolved']['publish']

          if link['role'] == 'creator'
            make_name(xml, link['_resolved'])
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

        # Language -> language/languageTerm
        if jsonmodel['language']
          xml.language { xml.languageTerm({'authority' => 'iso639-2b'}, jsonmodel['language']) }
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
            when 'altformavail'
              xml.note({'type' => 'additionalform'}, content)
            when 'accessrestrict'
              xml.accessCondition({'type' => 'restrictionOnAccess'}, content)
            when 'userestrict'
              xml.accessCondition({'type' => 'useAndReproduction'}, content)
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
            xml.subject { make_name(xml, link['_resolved'], {'type' => 'personal'}) }
          when 'agent_corporate_entity'
            xml.subject { make_name(xml, link['_resolved'], {'type' => 'corporate'}) }
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


  def make_name(xml, agent, attrs = {})
    if (auth = agent['display_name']['authority_id'])
      begin
        # testing scheme here because guessing the jira means URL
        if URI(auth).scheme
          attrs['authority'] = auth
        end
      rescue URI::InvalidURIError
        # only include authority if it is a valid URI
        # https://archivesspace.atlassian.net/browse/ANW-212
      end
    end

    xml.name(attrs) {
      xml.namePart(agent['title'])

      if agent['agent_type'] == 'agent_person'
        if agent['display_name']['name_order'] == 'inverted'
          xml.namePart({'type' => 'family'}, agent['display_name']['primary_name'])
          xml.namePart({'type' => 'given'}, agent['display_name']['rest_of_name'])
        else
          xml.namePart({'type' => 'given'}, agent['display_name']['primary_name'])
        end

        if (dates_of = agent['dates_of_existence'][0])
          date = [dates_of['begin'], dates_of['end']].join('/')
          xml.namePart({'type' => 'date'}, date)
        end

        if (prefix = agent['display_name']['prefix'])
          xml.namePart({'type' => 'termsOfAddress'}, prefix)
        end
      end
    }
  end

end
