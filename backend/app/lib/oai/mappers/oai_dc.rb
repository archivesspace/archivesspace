require_relative 'oai_utils'

class OAIDCMapper

  def map_oai_record(record)
    jsonmodel = record.jsonmodel_record
    result = Nokogiri::XML::Builder.new do |xml|
      xml['oai_dc'].dc('xmlns:oai_dc' => 'http://www.openarchives.org/OAI/2.0/oai_dc/',
                       'xmlns:dc' => 'http://purl.org/dc/elements/1.1/',
                       'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                       'xsi:schemaLocation' => 'http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd') do
        # Repo name -> publisher
        xml['dc'].publisher (jsonmodel['repository']['_resolved']['name'])

        # Parent institution name -> publisher
        if jsonmodel['repository']['_resolved']['parent_institution_name']
          xml['dc'].publisher(jsonmodel['repository']['_resolved']['parent_institution_name'])
        end

        # Identifier (own component ID + IDs of parents)
        merged_identifier = if jsonmodel['jsonmodel_type'] == 'archival_object'
                              ([jsonmodel['component_id']] + jsonmodel['ancestors'].map {|a| a['_resolved']['component_id']}).compact.reverse.uniq.join(".")
                            else
                              (0..3).map {|id| jsonmodel["id_#{id}"]}.compact.join('.')
                            end

        unless merged_identifier.empty?
          xml['dc'].identifier(merged_identifier)
        end

        # And a second identifier containing the public url - if public is running
        if AppConfig[:enable_public]
          xml['dc'].identifier(AppConfig[:public_proxy_url] + jsonmodel['uri'])
        end

        # Creator -- agents linked with role 'creator' that don't have a relator of 'contributor' or 'publisher'
        Array(jsonmodel['linked_agents']).each do |link|
          next unless link['_resolved']['publish']

          if link['role'] == 'creator' && !['ctb' ,'pbl'].include?(link['relator'])
            xml['dc'].creator(link['_resolved']['title'])
          end
        end

        # Contributor -- agents linked with role 'creator' and relator of 'contributor'
        Array(jsonmodel['linked_agents']).each do |link|
          next unless link['_resolved']['publish']

          if link['role'] == 'creator' && ['ctb'].include?(link['relator'])
            xml['dc'].contributor(link['_resolved']['title'])
          end
        end

        # Publisher -- agents linked with role 'creator' and relator of 'publisher'
        Array(jsonmodel['linked_agents']).each do |link|
          next unless link['_resolved']['publish']

          if link['role'] == 'creator' && ['pbl'].include?(link['relator'])
            xml['dc'].publisher(link['_resolved']['title'])
          end
        end

        # Title -- display string
        xml['dc'].title(OAIUtils.display_string(jsonmodel))

        # Dates
        Array(jsonmodel['dates']).each do |date|
          if date['expression']
            xml['dc'].date(date['expression'])
          else
            date_str = [date['begin'], date['end']].compact.join(" -- ")
            xml['dc'].date(date_str)
          end
        end

        # Extents
        Array(jsonmodel['extents']).each do |extent|
          extent_str = [extent['number'] + ' ' + I18n.t('enumerations.extent_extent_type.' + extent['extent_type'], :default => extent['extent_type']), extent['container_summary']].compact.join('; ')
          xml['dc'].format(extent_str)
        end

        # Physical description and Dimensions notes are also extents
        Array(jsonmodel['notes'])
          .select {|note| ['physdesc', 'dimensions'].include?(note['type'])}
          .each do |note|
          OAIUtils.extract_published_note_content(note).each do |content|
            xml['dc'].format(content)
          end
        end

        # Language
        if jsonmodel['language']
          xml['dc'].language(jsonmodel['language'])
        end

        # Description note types
        Array(jsonmodel['notes'])
          .select {|note| ['langmaterial', 'bioghist', 'scopecontent', 'abstract', 'odd', 'arrangement'].include?(note['type'])}
          .each do |note|
          OAIUtils.extract_published_note_content(note).each do |content|
            xml['dc'].description(content)
          end
        end

        # Relation note types
        Array(jsonmodel['notes'])
          .select {|note| ['originalsloc', 'altformavail', 'separatedmaterial', 'relatedmaterial'].include?(note['type'])}
          .each do |note|
          OAIUtils.extract_published_note_content(note).each do |content|
            xml['dc'].relation(content)
          end
        end

        # Rights note types
        Array(jsonmodel['notes'])
          .select {|note| ['accessrestrict', 'userestrict'].include?(note['type'])}
          .each do |note|
          OAIUtils.extract_published_note_content(note).each do |content|
            xml['dc'].rights(content)
          end
        end

        # Subjects
        Array(jsonmodel['subjects']).each do |subject|
          term_types = subject['_resolved']['terms'].map {|term| term['term_type']}

          if term_types.include?('geographic')
            xml['dc'].coverage(subject['_resolved']['title'])
          elsif term_types.include?('genre_form')
            xml['dc'].type(subject['_resolved']['title'])
          else
            xml['dc'].subject(subject['_resolved']['title'])
          end
        end

        # Subjects continued - Agents as subjects
        Array(jsonmodel['linked_agents']).each do |link|
          next unless link['_resolved']['publish']

          if link['role'] == 'subject'
            xml['dc'].subject(link['_resolved']['title'])
          end
        end


        # Physical facet note
        Array(jsonmodel['notes'])
          .select {|note| ['physfacet'].include?(note['type'])}
          .each do |note|
          OAIUtils.extract_published_note_content(note).each do |content|
            xml['dc'].type(content)
          end
        end

        # Originating Collection
        if jsonmodel['jsonmodel_type'] == 'archival_object'
          resource_id_str = (0..3).map {|i| jsonmodel['resource']['_resolved']["id_#{i}"]}.compact.join(".")
          resource_str = [jsonmodel['resource']['_resolved']['title'], resource_id_str].join(', ')

          xml['dc'].relation(resource_str)
        end
      end
    end

    result.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::NO_DECLARATION)
  end

end
