require 'nokogiri'
require 'securerandom'
require_relative "../lib/serialize_extra_container_values" 
class EADSerializer < ASpaceExport::Serializer
  serializer_for :ead

  include SerializeExtraContainerValues
  def prefix_id(id)
    if id.nil? or id.empty? or id == 'null'   
      ""
    elsif id =~ /^#{@id_prefix}/ 
      id
    else 
      "#{@id_prefix}#{id}"
    end 
  end
 
  def handle_linebreaks(content)
    # if there's already p tags, just leave as is 
    return content if ( content.strip.start_with?("<p") or content.strip.length < 1 ) 
    blocks = content.split("\n\n").select { |b| !b.strip.empty? }
    if blocks.length > 1
      content = blocks.inject("") { |c,n| c << "<p>#{n.chomp}</p>"  }
    else
      content = "<p>#{content.strip}</p>"
    end
    content
  end

  def strip_p(content)
    content.gsub("<p>", "").gsub("</p>", "").gsub("<p/>", '')
  end

  def sanitize_mixed_content(content, context, fragments, allow_p = false  )
#    return "" if content.nil? 
    # br's should be self closing 
    content = content.gsub("<br>", "<br/>").gsub("</br>", '')
    # lets break the text, if it has linebreaks but no p tags.  
    
    if allow_p 
      content = handle_linebreaks(content) 
    else
      content = strip_p(content)
    end
    
    begin 
      if ASpaceExport::Utils.has_html?(content)
         context.text( fragments << content )
      else
        context.text content
      end
    rescue
      context.cdata content
    end
  end
  
  def stream(data)
    @stream_handler = ASpaceExport::StreamHandler.new
    @fragments = ASpaceExport::RawXMLHandler.new
    @include_unpublished = data.include_unpublished?
    @use_numbered_c_tags = data.use_numbered_c_tags?
    @id_prefix = I18n.t('archival_object.ref_id_export_prefix', :default => 'aspace_')

    doc = Nokogiri::XML::Builder.new(:encoding => "UTF-8") do |xml|
      begin 

      xml.ead(                  'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                 'xsi:schemaLocation' => 'urn:isbn:1-931666-22-9 http://www.loc.gov/ead/ead.xsd',
                 'xmlns:xlink' => 'http://www.w3.org/1999/xlink') {

        xml.text (
          @stream_handler.buffer { |xml, new_fragments|
            serialize_eadheader(data, xml, new_fragments)
          })

        atts = {:level => data.level, :otherlevel => data.other_level}

        if data.publish === false
          if @include_unpublished
            atts[:audience] = 'internal'
          else
            return
          end
        end

        atts.reject! {|k, v| v.nil?}

        xml.archdesc(atts) {
            


          xml.did {
          

            if (val = data.language)
              xml.langmaterial {
                xml.language(:langcode => val) {
                  xml.text I18n.t("enumerations.language_iso639_2.#{val}", :default => val)
                }
              }
            end

            if (val = data.repo.name)
              xml.repository {
                xml.corpname { sanitize_mixed_content(val, xml, @fragments) }
              }
            end

            if (val = data.title)
              xml.unittitle  {   sanitize_mixed_content(val, xml, @fragments) } 
            end

            serialize_origination(data, xml, @fragments)

            xml.unitid (0..3).map{|i| data.send("id_#{i}")}.compact.join('.')

            serialize_extents(data, xml, @fragments)

            serialize_dates(data, xml, @fragments)

            serialize_did_notes(data, xml, @fragments)

            data.instances_with_containers.each do |instance|
              serialize_container(instance, xml, @fragments)
            end

          }# </did>
            
          data.digital_objects.each do |dob|
                serialize_digital_object(dob, xml, @fragments)
          end

          serialize_nondid_notes(data, xml, @fragments)

          serialize_bibliographies(data, xml, @fragments)

          serialize_indexes(data, xml, @fragments)

          serialize_controlaccess(data, xml, @fragments)

          xml.dsc {

            data.children_indexes.each do |i|
              xml.text(
                       @stream_handler.buffer {|xml, new_fragments|
                         serialize_child(data.get_child(i), xml, new_fragments)
                       }
                       )
            end
          }
        }
      }
    
    rescue => e
      xml.text  "ASPACE EXPORT ERROR : YOU HAVE A PROBLEM WITH YOUR EXPORT OF YOUR RESOURCE. THE FOLLOWING INFORMATION MAY HELP:\n
                MESSAGE: #{e.message.inspect}  \n
                TRACE: #{e.backtrace.inspect} \n "
    end
 
    
    
    end
    doc.doc.root.add_namespace nil, 'urn:isbn:1-931666-22-9'

    Enumerator.new do |y|
      @stream_handler.stream_out(doc, @fragments, y)
    end
  
    
  end
  
  # this extracts <head> content and returns it. optionally, you can provide a
  # backup text node that will be returned if there is no <head> nodes in the
  # content
  def extract_head_text(content, backup = "")
    content ||= ""  
    match = content.strip.match(/<head( [^<>]+)?>(.+?)<\/head>/)
    if match.nil? # content has no head so we return it as it
      return [content, backup ]
    else
      [ content.gsub(match.to_a.first, ''), match.to_a.last]
    end
  end

  def serialize_child(data, xml, fragments, c_depth = 1)
    begin 
    return if data["publish"] === false && !@include_unpublished

    tag_name = @use_numbered_c_tags ? :"c#{c_depth.to_s.rjust(2, '0')}" : :c

    atts = {:level => data.level, :otherlevel => data.other_level, :id => prefix_id(data.ref_id)}

    if data.publish === false
      atts[:audience] = 'internal'
    end

    atts.reject! {|k, v| v.nil?}
    xml.send(tag_name, atts) {

      xml.did {
        if (val = data.title)
          xml.unittitle {  sanitize_mixed_content( val,xml, fragments) } 
        end

        if !data.component_id.nil? && !data.component_id.empty?
          xml.unitid data.component_id
        end

        serialize_origination(data, xml, fragments)
        serialize_extents(data, xml, fragments)
        serialize_dates(data, xml, fragments)
        serialize_did_notes(data, xml, fragments)

        # TODO: Clean this up more; there's probably a better way to do this.
        # For whatever reason, the old ead_containers method was not working
        # on archival_objects (see migrations/models/ead.rb).

        data.instances.each do |inst|
          case 
          when inst.has_key?('container') && !inst['container'].nil?
            serialize_container(inst, xml, fragments)
          when inst.has_key?('digital_object') && !inst['digital_object']['_resolved'].nil?
            serialize_digital_object(inst['digital_object']['_resolved'], xml, fragments)
          end
        end

      }

      serialize_nondid_notes(data, xml, fragments)

      serialize_bibliographies(data, xml, fragments)

      serialize_indexes(data, xml, fragments)

      serialize_controlaccess(data, xml, fragments)

      data.children_indexes.each do |i|
        xml.text(
                 @stream_handler.buffer {|xml, new_fragments|
                   serialize_child(data.get_child(i), xml, new_fragments, c_depth + 1)
                 }
                 )
      end
    }
    rescue => e
      xml.text "ASPACE EXPORT ERROR : YOU HAVE A PROBLEM WITH YOUR EXPORT OF ARCHIVAL OBJECTS. THE FOLLOWING INFORMATION MAY HELP:\n

                MESSAGE: #{e.message.inspect}  \n
                TRACE: #{e.backtrace.inspect} \n "
    end
  end


  def serialize_origination(data, xml, fragments)
    unless data.creators_and_sources.nil?
      data.creators_and_sources.each do |link|
        agent = link['_resolved']
        role = link['role']
        relator = link['relator']
        sort_name = agent['display_name']['sort_name']
        rules = agent['display_name']['rules']
        source = agent['display_name']['source']
        node_name = case agent['agent_type']
                    when 'agent_person'; 'persname'
                    when 'agent_family'; 'famname'
                    when 'agent_corporate_entity'; 'corpname'
                    end
        xml.origination(:label => role) {
         atts = {:role => relator, :source => source, :rules => rules}
         atts.reject! {|k, v| v.nil?}

          xml.send(node_name, atts) {
            sanitize_mixed_content(sort_name, xml, fragments ) 
          }
        }
      end
    end
  end

  def serialize_controlaccess(data, xml, fragments)
    if (data.controlaccess_subjects.length + data.controlaccess_linked_agents.length) > 0
      xml.controlaccess {

        data.controlaccess_subjects.each do |node_data|
          xml.send(node_data[:node_name], node_data[:atts]) {
            sanitize_mixed_content( node_data[:content], xml, fragments, ASpaceExport::Utils.include_p?(node_data[:node_name]) ) 
          }
        end


        data.controlaccess_linked_agents.each do |node_data|
          xml.send(node_data[:node_name], node_data[:atts]) {
            sanitize_mixed_content( node_data[:content], xml, fragments,ASpaceExport::Utils.include_p?(node_data[:node_name]) ) 
          }
        end

      } #</controlaccess>
    end
  end

  def serialize_subnotes(subnotes, xml, fragments, include_p = true)
    subnotes.each do |sn|
      next if sn["publish"] === false && !@include_unpublished

      audatt = sn["publish"] === false ? {:audience => 'internal'} : {}

      title = sn['title']

      case sn['jsonmodel_type']
      when 'note_text'
        sanitize_mixed_content(sn['content'], xml, fragments, include_p )
      when 'note_chronology'
        xml.chronlist(audatt) {
          xml.head { sanitize_mixed_content(title, xml, fragments) } if title

          sn['items'].each do |item|
            xml.chronitem {
              if (val = item['event_date'])
                xml.date {   sanitize_mixed_content( val, xml, fragments) } 
              end
              if item['events'] && !item['events'].empty?
                xml.eventgrp {
                  item['events'].each do |event|
                    xml.event {   sanitize_mixed_content(event,xml, fragments) }  
                  end
                }
              end
            }
          end
        }
      when 'note_orderedlist'
        atts = {:type => 'ordered', :numeration => sn['enumeration']}.reject{|k,v| v.nil? || v.empty? || v == "null" }.merge(audatt)
        xml.list(atts) {
          xml.head { sanitize_mixed_content(title, xml, fragments) }  if title

          sn['items'].each do |item|
            xml.item { sanitize_mixed_content(item,xml, fragments)} 
          end
        }
      when 'note_definedlist'
        xml.list({:type => 'deflist'}.merge(audatt)) {
          xml.head { sanitize_mixed_content(title,xml, fragments) }  if title

          sn['items'].each do |item|
            xml.defitem {
              xml.label { sanitize_mixed_content(item['label'], xml, fragments) } if item['label']
              xml.item { sanitize_mixed_content(item['value'],xml, fragments )} if item['value']
            } 
          end
        }
      end
    end
  end

  def serialize_container(inst, xml, fragments)
    containers = []
    @parent_id = nil 
    (1..3).each do |n|
      atts = {}
      next unless inst['container'].has_key?("type_#{n}") && inst['container'].has_key?("indicator_#{n}")
      @container_id = prefix_id(SecureRandom.hex) 
      
      atts[:parent] = @parent_id unless @parent_id.nil? 
      atts[:id] = @container_id 
      @parent_id = @container_id 

      atts[:type] = inst['container']["type_#{n}"]
      text = inst['container']["indicator_#{n}"]
      if n == 1 && inst['instance_type']
        atts[:label] = I18n.t("enumerations.instance_instance_type.#{inst['instance_type']}", :default => inst['instance_type'])
      end
      xml.container(atts) {
         sanitize_mixed_content(text, xml, fragments)  
      }
    end
  end

  def serialize_digital_object(digital_object, xml, fragments)
    return if digital_object["publish"] === false && !@include_unpublished
    file_versions = digital_object['file_versions']
    title = digital_object['title']
    date = digital_object['dates'][0] || {}
    
    atts = digital_object["publish"] === false ? {:audience => 'internal'} : {}

    content = ""
    content << title if title
    content << ": " if date['expression'] || date['begin']
    if date['expression']
      content << date['expression']
    elsif date['begin']
      content << date['begin']
      if date['end'] != date['begin']
        content << "-#{date['end']}"
      end
    end
    atts['xlink:title'] = digital_object['title'] if digital_object['title']
    
    
    if file_versions.empty?
      atts['xlink:href'] = digital_object['digital_object_id']
      atts['xlink:actuate'] = 'onRequest'
      atts['xlink:show'] = 'new'
      xml.dao(atts) {
        xml.daodesc{ sanitize_mixed_content(content, xml, fragments, true) } if content
      }
    else
      file_versions.each do |file_version|
        atts['xlink:href'] = file_version['file_uri'] || digital_object['digital_object_id']
        atts['xlink:actuate'] = file_version['xlink_actuate_attribute'] || 'onRequest'
        atts['xlink:show'] = file_version['xlink_show_attribute'] || 'new'
        xml.dao(atts) {
          xml.daodesc{ sanitize_mixed_content(content, xml, fragments, true) } if content
        }
      end
    end
    
  end


  def serialize_extents(obj, xml, fragments)
    if obj.extents.length
      obj.extents.each do |e|
        next if e["publish"] === false && !@include_unpublished
        audatt = e["publish"] === false ? {:audience => 'internal'} : {}
        xml.physdesc({:altrender => e['portion']}.merge(audatt)) {
          if e['number'] && e['extent_type']
            xml.extent({:altrender => 'materialtype spaceoccupied'}) {
              sanitize_mixed_content("#{e['number']} #{I18n.t('enumerations.extent_extent_type.'+e['extent_type'], :default => e['extent_type'])}", xml, fragments)  
            }
          end
          if e['container_summary']
            xml.extent({:altrender => 'carrier'}) {
              sanitize_mixed_content( e['container_summary'], xml, fragments)
            }
          end
          xml.physfacet { sanitize_mixed_content(e['physical_details'],xml, fragments) } if e['physical_details']
          xml.dimensions  {   sanitize_mixed_content(e['dimensions'],xml, fragments) }  if e['dimensions']
        }
      end
    end
  end


  def serialize_dates(obj, xml, fragments)
    obj.archdesc_dates.each do |node_data|
      next if node_data["publish"] === false && !@include_unpublished
      audatt = node_data["publish"] === false ? {:audience => 'internal'} : {}
      xml.unitdate(node_data[:atts].merge(audatt)){
        sanitize_mixed_content( node_data[:content],xml, fragments ) 
      }
    end
  end


  def serialize_did_notes(data, xml, fragments)
    data.notes.each do |note|
      next if note["publish"] === false && !@include_unpublished
      next unless data.did_note_types.include?(note['type'])

      audatt = note["publish"] === false ? {:audience => 'internal'} : {}
      content = ASpaceExport::Utils.extract_note_text(note, @include_unpublished)

      att = { :id => prefix_id(note['persistent_id']) }.reject {|k,v| v.nil? || v.empty? || v == "null" } 
      att ||= {}

      case note['type']
      when 'dimensions', 'physfacet'
        xml.physdesc(audatt) {
          xml.send(note['type'], att) {
            sanitize_mixed_content( content, xml, fragments, ASpaceExport::Utils.include_p?(note['type'])  ) 
          }
        }
      else
        xml.send(note['type'], att.merge(audatt)) {
          sanitize_mixed_content(content, xml, fragments,ASpaceExport::Utils.include_p?(note['type']))
        }
      end
    end
  end

  def serialize_note_content(note, xml, fragments)
    return if note["publish"] === false && !@include_unpublished
    audatt = note["publish"] === false ? {:audience => 'internal'} : {}
    content = note["content"] 

    atts = {:id => prefix_id(note['persistent_id']) }.reject{|k,v| v.nil? || v.empty? || v == "null" }.merge(audatt)
    
    head_text = note['label'] ? note['label'] : I18n.t("enumerations._note_types.#{note['type']}", :default => note['type'])
    content, head_text = extract_head_text(content, head_text) 
    xml.send(note['type'], atts) {
      xml.head { sanitize_mixed_content(head_text, xml, fragments) } unless ASpaceExport::Utils.headless_note?(note['type'], content ) 
      sanitize_mixed_content(content, xml, fragments, ASpaceExport::Utils.include_p?(note['type']) ) if content
      if note['subnotes']
        serialize_subnotes(note['subnotes'], xml, fragments, ASpaceExport::Utils.include_p?(note['type']))
      end
    }
  end


  def serialize_nondid_notes(data, xml, fragments)
    data.notes.each do |note|
      next if note["publish"] === false && !@include_unpublished
      next if note['internal']
      next if note['type'].nil?
      next unless data.archdesc_note_types.include?(note['type'])
      audatt = note["publish"] === false ? {:audience => 'internal'} : {}
      if note['type'] == 'legalstatus'
        xml.accessrestrict(audatt) {
          serialize_note_content(note, xml, fragments) 
        }
      else
        serialize_note_content(note, xml, fragments)
      end
    end
  end


  def serialize_bibliographies(data, xml, fragments)
    data.bibliographies.each do |note|
      next if note["publish"] === false && !@include_unpublished
      content = ASpaceExport::Utils.extract_note_text(note, @include_unpublished)
      note_type = note["type"] ? note["type"] : "bibliography" 
      head_text = note['label'] ? note['label'] : I18n.t("enumerations._note_types.#{note_type}", :default => note_type )
      audatt = note["publish"] === false ? {:audience => 'internal'} : {}
      
      atts = {:id => prefix_id(note['persistent_id']) }.reject{|k,v| v.nil? || v.empty? || v == "null" }.merge(audatt)

      xml.bibliography(atts) {
        xml.head { sanitize_mixed_content(head_text, xml, fragments) } 
        sanitize_mixed_content( content, xml, fragments, true) 
        note['items'].each do |item|
          xml.bibref { sanitize_mixed_content( item, xml, fragments) }  unless item.empty?
        end
      }
    end
  end


  def serialize_indexes(data, xml, fragments)
    data.indexes.each do |note|
      next if note["publish"] === false && !@include_unpublished
      audatt = note["publish"] === false ? {:audience => 'internal'} : {}
      content = ASpaceExport::Utils.extract_note_text(note, @include_unpublished)
      head_text = nil
      if note['label']
        head_text = note['label']
      elsif note['type']
        head_text = I18n.t("enumerations._note_types.#{note['type']}", :default => note['type'])
      end
      atts = {:id => prefix_id(note["persistent_id"]) }.reject{|k,v| v.nil? || v.empty? || v == "null" }.merge(audatt)

      content, head_text = extract_head_text(content, head_text) 
      xml.index(atts) {
        xml.head { sanitize_mixed_content(head_text,xml,fragments ) } unless head_text.nil?
        sanitize_mixed_content(content, xml, fragments, true)
        note['items'].each do |item|
          next unless (node_name = data.index_item_type_map[item['type']])
          xml.indexentry {
            atts = item['reference'] ? {:target => prefix_id( item['reference']) } : {}
            if (val = item['value'])
              xml.send(node_name) {  sanitize_mixed_content(val, xml, fragments )} 
            end
            if (val = item['reference_text'])
              xml.ref(atts) {
                sanitize_mixed_content( val, xml, fragments)
              }
            end
          }
        end
      }
    end
  end


  def serialize_eadheader(data, xml, fragments)
    eadheader_atts = {:findaidstatus => data.finding_aid_status,
                      :repositoryencoding => "iso15511",
                      :countryencoding => "iso3166-1",
                      :dateencoding => "iso8601",
                      :langencoding => "iso639-2b"}.reject{|k,v| v.nil? || v.empty? || v == "null"}

    xml.eadheader(eadheader_atts) {

      eadid_atts = {:countrycode => data.repo.country,
              :url => data.ead_location,
              :mainagencycode => data.mainagencycode}.reject{|k,v| v.nil? || v.empty? || v == "null" }

      xml.eadid(eadid_atts) {
        xml.text data.ead_id
      }

      xml.filedesc {

        xml.titlestmt {

          titleproper = ""
          titleproper += "#{data.finding_aid_title} " if data.finding_aid_title
          titleproper += "#{data.title}" if ( data.title && titleproper.empty? )
          titleproper += "<num>#{(0..3).map{|i| data.send("id_#{i}")}.compact.join('.')}</num>"
          xml.titleproper("type" => "filing") { sanitize_mixed_content(data.finding_aid_filing_title, xml, fragments)} unless data.finding_aid_filing_title.nil?
          xml.titleproper {  sanitize_mixed_content(titleproper, xml, fragments) }
          xml.subtitle {  sanitize_mixed_content(data.finding_aid_subtitle, xml, fragments) } unless data.finding_aid_subtitle.nil?
          xml.author { sanitize_mixed_content(data.finding_aid_author, xml, fragments) }  unless data.finding_aid_author.nil?
          xml.sponsor { sanitize_mixed_content( data.finding_aid_sponsor, xml, fragments) } unless data.finding_aid_sponsor.nil?
      
        }

        unless data.finding_aid_edition_statement.nil?
          xml.editionstmt {
            sanitize_mixed_content(data.finding_aid_edition_statement, xml, fragments, true )
          }
        end

        xml.publicationstmt {
          xml.publisher { sanitize_mixed_content(data.repo.name,xml, fragments) } 

          if data.repo.image_url
            xml.p ( { "id" => "logostmt" } ) {
              xml.extref ({"xlink:href" => data.repo.image_url,
                          "xlink:actuate" => "onLoad",
                          "xlink:show" => "embed",
                          "xlink:type" => "simple" 
                          })
                          }
          end
          if (data.finding_aid_date)
            xml.p {
                  val = data.finding_aid_date   
                  xml.date {   sanitize_mixed_content( val, xml, fragments) }
                  }
          end

          unless data.addresslines.empty?
            xml.address {
              data.addresslines.each do |line|
                xml.addressline { sanitize_mixed_content( line, xml, fragments) }  
              end
              if data.repo.url 
              	xml.addressline ( "URL: " ) { 
              	  xml.extptr ( { 
              	  				"xlink:href" => data.repo.url,
              	  				"xlink:title" => data.repo.url,
              	  				"xlink:type" => "simple",
              	  				"xlink:show" => "new"
              	  				} )
              	 }
              end
            }
          end
        }

        if (data.finding_aid_series_statement)
          val = data.finding_aid_series_statement
          xml.seriesstmt {
            sanitize_mixed_content(  val, xml, fragments, true ) 
          }
        end
        if ( data.finding_aid_note )
            val = data.finding_aid_note 
            xml.notestmt { xml.note { sanitize_mixed_content(  val, xml, fragments, true )} }  
        end
       
      }

      xml.profiledesc {
        creation = "This finding aid was produced using ArchivesSpace on <date>#{Time.now}</date>."
        xml.creation {  sanitize_mixed_content( creation, xml, fragments) }

        if (val = data.finding_aid_language)
          xml.langusage (fragments << val)
        end

        if (val = data.descrules)
          xml.descrules { sanitize_mixed_content(val, xml, fragments) } 
        end
      }

      if data.revision_statements.length > 0
        xml.revisiondesc {
          data.revision_statements.each do |rs|
              if rs['description'] && rs['description'].strip.start_with?('<')
                xml.text (fragments << rs['description'] )
              else
                xml.change {
                  rev_date = rs['date'] ? rs['date'] : "" 
                  xml.date (fragments <<  rev_date ) 
                  xml.item (fragments << rs['description']) if rs['description']
                }
              end
          end
        } 
      end
    }
  end
end
