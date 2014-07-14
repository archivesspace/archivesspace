require 'nokogiri'
require 'securerandom'

class EADSerializer < ASpaceExport::Serializer
  serializer_for :ead
  
  def has_html?(text)
    ASpaceExport::Utils.has_html?(text)
  end
 
  def cdata_or_p(content, xml)
    if has_html?(content)
      xml.p {xml.cdata content}
    else
      xml.p content
    end
  end

  def cdata_or_text(content, xml)
    if has_html?(content)
      xml.cdata content
    else
      xml.text content
    end
  end 

  # this extracts <head> content and returns it. optionally, you can provide a
  # backup text node that will be returned if there is no <head> nodes in the
  # content
  def extract_head_text(content, backup = "")
    match = content.strip.match(/<head( [^<>]+)?>(.+?)<\/head>/)
    if match.nil? # content has no head so we return it as it
      return [content, backup ]
    else
      [ content.gsub(match.to_a.first, ''), match.to_a.last]
    end
  end
  
  def stream(data)

    @stream_handler = ASpaceExport::StreamHandler.new
    @fragments = ASpaceExport::RawXMLHandler.new
    @include_unpublished = data.include_unpublished?
    @use_numbered_c_tags = data.use_numbered_c_tags?

    doc = Nokogiri::XML::Builder.new(:encoding => "UTF-8") do |xml|

      xml.ead('xmlns' => 'urn:isbn:1-931666-22-9',
                 'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
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

          data.digital_objects.each do |dob|
            serialize_digital_object(dob, xml, @fragments)
          end

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
                xml.corpname val
              }
            end

            if (val = data.title)
              xml.unittitle { cdata_or_text(val, xml) }
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
    end

    Enumerator.new do |y|
      @stream_handler.stream_out(doc, @fragments, y)
    end
  end


  def serialize_child(data, xml, fragments, c_depth = 1)
    return if data["publish"] === false && !@include_unpublished

    tag_name = @use_numbered_c_tags ? :"c#{c_depth.to_s.rjust(2, '0')}" : :c

    prefixed_ref_id = "#{I18n.t('archival_object.ref_id_export_prefix', :default => 'aspace_')}#{data.ref_id}"
    atts = {:level => data.level, :otherlevel => data.other_level, :id => prefixed_ref_id}

    if data.publish === false
      atts[:audience] = 'internal'
    end

    atts.reject! {|k, v| v.nil?}
    xml.send(tag_name, atts) {

      xml.did {
        if (val = data.title)
          xml.unittitle { cdata_or_text( val, xml ) }
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
            cdata_or_text( sort_name, xml )
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
            cdata_or_text( node_data[:content], xml)
          }
        end


        data.controlaccess_linked_agents.each do |node_data|
          xml.send(node_data[:node_name], node_data[:atts]) {
            cdata_or_text( node_data[:content], xml)
          }
        end

      } #</controlaccess>
    end
  end

  def serialize_subnotes(subnotes, xml, fragments)
    subnotes.each do |sn|
      next if sn["publish"] === false && !@include_unpublished

      audatt = sn["publish"] === false ? {:audience => 'internal'} : {}

      title = sn['title']

      case sn['jsonmodel_type']
      when 'note_chronology'
        xml.chronlist(audatt) {
          xml.head { cdata_or_text( title, xml) } if title

          sn['items'].each do |item|
            xml.chronitem {
              if (val = item['event_date'])
                xml.date val
              end
              if item['events'] && !item['events'].empty?
                xml.eventgrp {
                  item['events'].each do |event|
                    xml.event event
                  end
                }
              end
            }
          end
        }
      when 'note_orderedlist'
        atts = {:type => 'ordered', :numeration => sn['enumeration']}.reject{|k,v| v.nil? || v.empty? || v == "null" }.merge(audatt)
        xml.list(atts) {
          xml.head { cdata_or_text( title, xml) } if title

          sn['items'].each do |item|
            xml.item { cdata_or_text(item, xml) }
          end
        }
      when 'note_definedlist'
        xml.list({:type => 'deflist'}.merge(audatt)) {
          xml.head { cdata_or_text( title, xml) } if title

          sn['items'].each do |item|
            xml.defitem {
              xml.label item['label'] if item['label']
              xml.item { cdata_or_text(item['value'], xml) } if item['value']
            } 
          end
        }
      end
    end
  end

  def serialize_container(inst, xml, fragments)
    containers = []
    (1..3).each do |n|
      atts = {}
      next unless inst['container'].has_key?("type_#{n}") && inst['container'].has_key?("indicator_#{n}")
      atts[:type] = inst['container']["type_#{n}"]
      text = inst['container']["indicator_#{n}"]
      if n == 1 && inst['instance_type']
        atts[:label] = I18n.t("enumerations.instance_instance_type.#{inst['instance_type']}", :default => inst['instance_type'])
      end
      xml.container(atts) {
        xml.text text
      }
    end
  end

  def serialize_digital_object(digital_object, xml, fragments)
    return if digital_object["publish"] === false && !@include_unpublished
    file_version = digital_object['file_versions'][0] || {}
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

    atts['xlink:href'] = file_version['file_uri'] || digital_object['digital_object_id']
    atts['xlink:title'] = digital_object['title'] if digital_object['title']
    atts['xlink:actuate'] = file_version['xlink_actuate_attribute'] || 'onRequest'
    atts['xlink:show'] = file_version['xlink_show_attribute'] || 'new'

    xml.dao(atts) {
      xml.daodesc{ cdata_or_p( content, xml) } if content
    }
  end


  def serialize_extents(obj, xml, fragments)
    if obj.extents.length
      obj.extents.each do |e|
        next if e["publish"] === false && !@include_unpublished
        audatt = e["publish"] === false ? {:audience => 'internal'} : {}
        xml.physdesc({:altrender => e['portion']}.merge(audatt)) {
          if e['number'] && e['extent_type']
            xml.extent({:altrender => 'materialtype spaceoccupied'}) {
              cdata_or_text( "#{e['number']} #{I18n.t('enumerations.extent_extent_type.'+e['extent_type'], :default => e['extent_type'])}", xml)
            }
          end
          if e['container_summary']
            xml.extent({:altrender => 'carrier'}) {
              cdata_or_text( e['container_summary'],xml)
            }
          end
          xml.physfacet { cdata_or_text(e['physical_details'],xml) } if e['physical_details']
          xml.dimensions cdata_or_text( e['dimensions'], xml) if e['dimensions']
        }
      end
    end
  end


  def serialize_dates(obj, xml, fragments)
    obj.archdesc_dates.each do |node_data|
      next if node_data["publish"] === false && !@include_unpublished
      audatt = node_data["publish"] === false ? {:audience => 'internal'} : {}
      xml.unitdate(node_data[:atts].merge(audatt)){
        xml.text node_data[:content]
      }
    end
  end


  def serialize_did_notes(data, xml, fragments)
    data.notes.each do |note|
      next if note["publish"] === false && !@include_unpublished
      next unless data.did_note_types.include?(note['type'])

      audatt = note["publish"] === false ? {:audience => 'internal'} : {}
      content = ASpaceExport::Utils.extract_note_text(note, @include_unpublished)
      prefixed_ref_id = "#{I18n.t('archival_object.ref_id_export_prefix', :default => 'aspace_')}#{note['persistent_id']}"
      att = prefixed_ref_id ? {:id => prefixed_ref_id} : {}

      case note['type']
      when 'dimensions', 'physfacet'
        xml.physdesc(audatt) {
          xml.send(note['type'], att) {
            xml.cdata (fragments << content) 
          }
        }
      else
        xml.send(note['type'], att.merge(audatt)) {
          xml.cdata (fragments << content) 
        }
      end
    end
  end

  def serialize_note_content(note, xml, fragments)
    return if note["publish"] === false && !@include_unpublished
    audatt = note["publish"] === false ? {:audience => 'internal'} : {}
    content = ASpaceExport::Utils.extract_note_text(note, @include_unpublished)
    prefixed_ref_id = "#{I18n.t('archival_object.ref_id_export_prefix', :default => 'aspace_')}#{note['persistent_id']}"
    atts = {:id => prefixed_ref_id }.reject{|k,v| v.nil? || v.empty?}.merge(audatt)
    head_text = note['label'] ? note['label'] : I18n.t("enumerations._note_types.#{note['type']}", :default => note['type'])
    content, head_text = extract_head_text(content, head_text) 
    xml.send(note['type'], atts) {
      xml.head head_text 
      xml.p { xml.cdata(fragments << content  ) } 
      
      if note['subnotes']
        serialize_subnotes(note['subnotes'], xml, fragments)
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
      head_text = note['label'] ? note['label'] : I18n.t("enumerations._note_types.#{note['type']}")
      audatt = note["publish"] === false ? {:audience => 'internal'} : {}
      prefixed_ref_id = "#{I18n.t('archival_object.ref_id_export_prefix', :default => 'aspace_')}#{note['persistent_id']}"
      atts = {:id => prefixed_ref_id }.reject{|k,v| v.nil? || v.empty?}.merge(audatt)

      xml.bibliography(atts) {
        xml.head head_text unless content.strip.start_with?('<head')
        if content.strip.start_with?('<')
          xml.text (fragments << content)
        else
          xml.p (fragments << content)
        end
        note['items'].each do |item|
          xml.bibref item unless item.empty?
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
      prefixed_ref_id = "#{I18n.t('archival_object.ref_id_export_prefix', :default => 'aspace_')}#{note['persistent_id']}"
      atts = {:id => prefixed_ref_id }.reject{|k,v| v.nil? || v.empty?}.merge(audatt)

      content, head_text = extract_head_text(content, head_text) 
      xml.index(atts) {
        xml.head head_text 
        cdata_or_p(content, xml) 
        note['items'].each do |item|
          next unless (node_name = data.index_item_type_map[item['type']])
          xml.indexentry {
            atts = item['reference'] ? {:target => item['reference']} : {}
            if (val = item['value'])
              xml.send(node_name) { cdata_or_text(val, xml)} 
            end
            if (val = item['reference_text'])
              xml.ref(atts) {
                xml.text val
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
                      :langencoding => "iso639-2b"}.reject{|k,v| v.nil? || v.empty?}

    xml.eadheader(eadheader_atts) {

      eadid_atts = {:countrycode => data.repo.country,
              :url => data.ead_location,
              :mainagencycode => data.mainagencycode}.reject{|k,v| v.nil? || v.empty?}

      xml.eadid(eadid_atts) {
        xml.text data.ead_id
      }

      xml.filedesc {

        xml.titlestmt {

          titleproper = ""
          titleproper += "#{data.finding_aid_title} " if data.finding_aid_title
          titleproper += "#{data.title}" if ( data.title && titleproper.empty? )
          titleproper += "<num>#{(0..3).map{|i| data.send("id_#{i}")}.compact.join('.')}</num>"
          titleproper += "<date>#{data.finding_aid_date}</date>" if data.finding_aid_date 
        
          xml.titleproper { cdata_or_text( (fragments << titleproper ), xml ) }

          xml.author { cdata_or_text( data.finding_aid_author, xml )} unless data.finding_aid_author.nil?
          xml.sponsor { cdata_or_text( data.finding_aid_sponsor, xml )} unless data.finding_aid_sponsor.nil?
        }

        unless data.finding_aid_edition_statement.nil?
          xml.editionstmt {
            cdata_or_p(data.finding_aid_edition_statement, xml)
          }
        end

        xml.publicationstmt {
          xml.publisher { cdata_or_text( data.repo.name,xml ) }

          if data.repo.image_url
            xml.p {
              xml.extref ({"xlink:href" => data.repo.image_url,
                          "xlink:actuate" => "onLoad",
                          "xlink:show" => "embed",
                          "xlink:linktype" => "simple"})
            }
          end

          unless data.addresslines.empty?
            xml.address {
              data.addresslines.each do |line|
                xml.addressline { cdata_or_text( line, xml ) }
              end
            }
          end
        }

        if (val = data.finding_aid_series_statement)
          xml.seriesstmt { cdata_or_p(( fragments << val ), xml) } 
        end
        if ( data.finding_aid_note )
            xml.notestmt { xml.note { cdata_or_p(( fragments << data.finding_aid_note ), xml )} }
        end
        
      }

      xml.profiledesc {
        creation = "This finding aid was produced using ArchivesSpace on <date>#{Time.now}</date>."
        xml.creation { cdata_or_text((fragments << creation), xml)}

        if (val = data.finding_aid_language)
          xml.langusage { cdata_or_text((fragments << val), xml)}
        end

        if (val = data.descrules)
          xml.descrules { cdata_or_text(val, xml ) }
        end
      }

      if data.finding_aid_revision_date || data.finding_aid_revision_description
        xml.revisiondesc {
          if data.finding_aid_revision_description && data.finding_aid_revision_description.strip.start_with?('<')
            cdata_or_text( (fragments << data.finding_aid_revision_description), xml )
          else
            xml.change {
              xml.date (fragments << data.finding_aid_revision_date) if data.finding_aid_revision_date
              xml.item { cdata_or_text( (fragments << data.finding_aid_revision_description), xml)} if data.finding_aid_revision_description
            }
          end
        }
      end
    }
  end
end
