require 'nokogiri'
require 'securerandom'
require 'uri'

class RawXMLHandler

  def initialize
    @fragments = {}
  end

  def <<(s)
    id = SecureRandom.hex
    @fragments[id] = s

    ":aspace_fragment_#{id}"
  end

  def substitute_fragments(xml_string)
    @fragments.each do |id, fragment|
      xml_string.gsub!(/:aspace_fragment_#{id}/, fragment)
      xml_string.gsub!(/[&]([^a])/, '&amp;\1')
    end

    xml_string
  end
end


class StreamHandler

  def initialize
    @sections = {}
    @depth = 0
  end


  def buffer(&block)
    id = SecureRandom.hex
    @sections[id] = block
    ":aspace_section_#{id}_"
  end


  def stream_out(doc, fragments, y, depth=0)
    xml_text = doc.to_xml
    xml_text.force_encoding('utf-8')
    queue = xml_text.split(":aspace_section")

    y << fragments.substitute_fragments(queue.shift)

    while queue.length > 0
      next_section = queue.shift
      next_id = next_section.slice!(/^_(\w+)_/).gsub(/_/, '')
      next_fragments = RawXMLHandler.new
      doc_frag = Nokogiri::XML::DocumentFragment.parse ""
      Nokogiri::XML::Builder.with(doc_frag) do |xml|
        @sections[next_id].call(xml, next_fragments)
      end
      stream_out(doc_frag, next_fragments, y, depth + 1)

      if next_section && !next_section.empty?
        y << fragments.substitute_fragments(next_section)
      end
    end
  end
end


ASpaceExport::serializer :ead do

  def stream(data)

    @stream_handler = StreamHandler.new
    @fragments = RawXMLHandler.new

    doc = Nokogiri::XML::Builder.new do |xml|

      xml.ead('xmlns' => 'urn:isbn:1-931666-22-9',
                 'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                 'xsi:schemaLocation' => 'urn:isbn:1-931666-22-9 http://www.loc.gov/ead/ead.xsd',
                 'xmlns:xlink' => 'http://www.w3.org/1999/xlink') {

        xml.text (
          @stream_handler.buffer { |xml, new_fragments|
            serialize_eadheader(data, xml, new_fragments)
          })

        xml.archdesc(:level => data.level) {

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
              xml.unittitle val
            end

            data.creators_and_sources.each do |link|
              agent = link['_resolved']
              role = link['role']
              relator = link['relator']
              sort_name = agent['names'][0]['sort_name']
              rules = agent['names'][0]['rules']
              source = agent['names'][0]['source']
              node_name = case agent['agent_type']
                          when 'agent_person'; 'persname'
                          when 'agent_family'; 'famname'
                          when 'agent_corporate_entity'; 'corpname'
                          end
              xml.origination(:label => role) {
               atts = {:relator => relator, :source => source, :rules => rules}
               atts.reject! {|k, v| v.nil?}

                xml.send(node_name, atts) {
                  xml.text sort_name
                }
              }
            end

            xml.unitid (0..3).map{|i| data.send("id_#{i}")}.compact.join('.')

            serialize_extents(data, xml, @fragments)

            serialize_dates(data, xml, @fragments)

            serialize_did_notes(data.notes, xml, @fragments)

            data.instances_with_containers.each do |instance|
              serialize_container(instance, xml, @fragments)
            end

          }# </did>

          data.notes.each do |note|
            next if note['internal']
            next unless data.archdesc_note_types.include?(note['type'])

            xml.text(
              @stream_handler.buffer { |xml, new_fragments|
                content = ASpaceExport::Utils.extract_note_text(note)
                head_text = note['label'] ? note['label'] : I18n.t("enumerations._note_types.#{note['type']}", :default => note['type'])
                atts = {:id => note['persistent_id']}.reject{|k,v| v.nil? || v.empty?}

                xml.send(note['type'], atts) {
                  xml.head head_text unless content.strip.start_with?('<head')
                  if content.strip.start_with?('<')
                    xml.text (new_fragments << content)
                  else
                    xml.p (new_fragments << content)
                  end

                  if note['subnotes']
                    serialize_subnotes(note['subnotes'], xml, new_fragments)
                  end
                }
              }
            )
          end

          data.bibliographies.each do |note|

            content = ASpaceExport::Utils.extract_note_text(note)
            head_text = note['label'] ? note['label'] : I18n.t("enumerations._note_types.#{note['type']}")
            atts = {:id => note['persistent_id']}.reject{|k,v| v.nil? || v.empty?}

            xml.bibliography(atts) {
              xml.head head_text unless content.strip.start_with?('<head')
              if content.strip.start_with?('<')
                xml.text (@fragments << content)
              else
                xml.p (@fragments << content)
              end
              note['items'].each do |item|
                xml.bibref item unless item.empty?
              end
            }
          end

          data.indexes.each do |note|

            content = ASpaceExport::Utils.extract_note_text(note)
            head_text = nil
            if note['label']
              head_text = note['label']
            elsif note['type']
              head_text = I18n.t("enumerations._note_types.#{note['type']}", :default => note['type'])
            end

            atts = {:id => note['persistent_id']}.reject{|k,v| v.nil? || v.empty?}

            xml.index(atts) {
              xml.head head_text unless content.strip.start_with?('<head')
              if content.strip.start_with?('<')
                xml.text (@fragments << content)
              else
                xml.p (@fragments << content)
              end
              note['items'].each do |item|
                next unless (node_name = data.index_item_type_map[item['type']])
                xml.indexentry {
                  atts = item['reference'] ? {:target => item['reference']} : {}
                  xml.ref(atts) {
                    xml.text item['reference_text']
                  }
                  if (val = item['value'])
                    xml.send(node_name, val)
                  end
                }
              end
            }
          end


          if (data.controlaccess_subjects.length + data.controlaccess_linked_agents.length) > 0
            xml.controlaccess {

              data.controlaccess_subjects.each do |node_data|
                xml.send(node_data[:node_name], node_data[:atts]) {
                  xml.text node_data[:content]
                }
              end


              data.controlaccess_linked_agents.each do |node_data|
                xml.send(node_data[:node_name], node_data[:atts]) {
                  xml.text node_data[:content]
                }
              end

            } #</controlaccess>
          end

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


  def serialize_child(obj, xml, fragments)
    xml.c(:level => obj.level, :id => obj.ref_id) {

      xml.did {
        xml.unittitle obj.title

        if (val = obj.component_id)
          xml.unitid val
        end

        serialize_extents(obj, xml, fragments)
        serialize_dates(obj, xml, fragments)
        serialize_did_notes(obj.notes, xml, fragments)

        # TODO: Clean this up more; there's probably a better way to do this.
        # For whatever reason, the old ead_containers method was not working
        # on archival_objects (see migrations/models/ead.rb).

        obj.instances.each do |inst|
          case 
          when inst.has_key?('container') && !inst['container'].nil?
            serialize_container(inst, xml, fragments)
          when inst.has_key?('digital_object') && !inst['digital_object']['_resolved'].nil?
            serialize_digital_object(inst['digital_object']['_resolved'], xml, fragments)
          end
        end

      }

      if (obj.controlaccess_subjects.length + obj.controlaccess_linked_agents.length) > 0
        xml.controlaccess {

          obj.controlaccess_subjects.each do |node_data|
            xml.send(node_data[:node_name], node_data[:atts]) {
              xml.text node_data[:content]
            }
          end


          obj.controlaccess_linked_agents.each do |node_data|
            xml.send(node_data[:node_name], node_data[:atts]) {
              xml.text node_data[:content]
            }
          end

        } #</controlaccess>
      end

      obj.children_indexes.each do |i|
        xml.text(
          @stream_handler.buffer {|xml, new_fragments|
            serialize_child(obj.get_child(i), xml, new_fragments)
          }
        )
      end
    }
  end


  def serialize_subnotes(subnotes, xml, fragments)
    subnotes.each do |sn|

      title = sn['title']

      case sn['jsonmodel_type']
      when 'note_chronology'
        xml.chronlist {
          xml.head title if title

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
        atts = {:type => 'ordered', :numeration => sn['enumeration']}.reject{|k,v| v.nil? || v.empty?}
        xml.list(atts) {
          xml.head title if title

          sn['items'].each do |item|
            xml.item item
          end
        }
      when 'note_definedlist'
        xml.list(:type => 'deflist') {
          xml.head title if title

          sn['items'].each do |item|
            xml.defitem {
              xml.label item['label'] if item['label']
              xml.item item['value'] if item['value']
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
    file_version = digital_object['file_versions'][0] || {}
    title = digital_object['title']
    date = digital_object['dates'][0] || {}
    atts = {}

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
      xml.daodesc{ xml.p(content) } if content
    }
  end


  def serialize_extents(obj, xml, fragments)
    if obj.ead_extents.length
      xml.physdesc {
        obj.ead_extents.each do |e|
          xml.extent e
        end
      }
    end
  end


  def serialize_dates(obj, xml, fragments)
    obj.archdesc_dates.each do |node_data|
      xml.unitdate(node_data[:atts]){
        xml.text node_data[:content]
      }
    end
  end


  def serialize_did_notes(notes, xml, fragments)
    notes.each do |note|
      next unless %w(abstract dimensions physdesc langmaterial physloc materialspec physfacet).include?(note['type'])

      content = ASpaceExport::Utils.extract_note_text(note)
      id = note['persistent_id']
      att = id ? {:id => id} : {}

      case note['type']
      when 'dimensions', 'physfacet'
        xml.physdesc {
          xml.send(note['type'], att) {
            xml.text (fragments << content)
          }
        }
      else
        xml.send(note['type'], att) {
          xml.text (fragments << content)
        }
      end
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
          titleproper += "#{data.title} " if data.title
          titleproper += "<num>#{(0..3).map{|i| data.send("id_#{i}")}.compact.join('.')}</num>"
          xml.titleproper (fragments << titleproper)

        }

        xml.publicationstmt {
          xml.publisher data.repo.name

          if data.repo.image_url
            xml.p {
              xml.extref ({"xlink:href" => data.repo.image_url,
                          "xlink:actuate" => "onLoad",
                          "xlink:show" => "embed",
                          "xlink:linktype" => "simple"})
            }
          end

          xml.address {
            data.addresslines.each do |line|
              xml.addressline line
            end
          }
        }

        if (val = data.finding_aid_series_statement)
          xml.seriesstmt {
            if val.strip.start_with?('<')
              xml.text (fragments << val)
            else
              xml.p (fragments << val)
            end
          }
        end
      }

      xml.profiledesc {
        creation = "This finding aid was produced using ArchivesSpace on <date>#{Time.now}</date>."
        xml.creation (fragments << creation)

        if (val = data.finding_aid_language)
          xml.langusage (fragments << val)
        end

        if (val = data.descrules)
          xml.descrules val
        end
      }

      if data.finding_aid_revision_date || data.finding_aid_revision_description
        xml.revisiondesc {
          if data.finding_aid_revision_description.strip.start_with?('<')
            xml.text (fragments << data.finding_aid_revision_description)
          else
            xml.change {
              xml.date (fragments << data.finding_aid_revision_date) if data.finding_aid_revision_date
              xml.item (fragments << data.finding_aid_revision_description) if data.finding_aid_revision_description
            }
          end
        }
      end
    }
  end
end
