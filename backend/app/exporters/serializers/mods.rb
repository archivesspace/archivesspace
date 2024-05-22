class MODSSerializer < ASpaceExport::Serializer
  serializer_for :mods

  include JSONModel

  def serialize(mods, opts = {})
    builder = Nokogiri::XML::Builder.new(:encoding => "UTF-8") do |xml|
      serialize_mods(mods, xml)
    end

    builder.to_xml
  end

  def serialize_mods(mods, xml)
    root_args = {'version' => '3.4'}
    root_args['xmlns'] = 'http://www.loc.gov/mods/v3'

    xml.mods(root_args) {
      serialize_mods_inner(mods, xml)
    }
  end

  def serialize_mods_inner(mods, xml)
    xml.titleInfo {
      xml.title mods.title
    }

    xml.identifier mods.identifier

    xml.typeOfResource mods.type_of_resource

    unless mods.lang_materials.nil?

      mods.lang_materials.each do |language|
        xml.language {
          xml.languageTerm(:type => 'text', :authority => 'iso639-2b') {
            xml.text I18n.t("enumerations.language_iso639_2." + language['language'])
          }

          xml.languageTerm(:type => 'code', :authority => 'iso639-2b') {
            xml.text language['language']
          }

          unless language['script'].nil?
            xml.scriptTerm(:type => 'text', :authority => 'iso15924') {
              xml.text I18n.t("enumerations.script_iso15924." + language['script'])
            }

            xml.scriptTerm(:type => 'code', :authority => 'iso15924') {
              xml.text language['script']
            }
          end
        }
      end

      mods.lang_notes.each do |note|
        serialize_note(note, xml)
      end

    end

    mods.dates.each do |date|
      handle_date(xml, date)
    end

    xml.physicalDescription {
      mods.extents.each do |extent|
        xml.extent extent
      end

      mods.extent_notes.each do |note|
        serialize_note(note, xml)
      end
    }

    mods.notes.each do |note|
      if note.wrapping_tag
        xml.send(note.wrapping_tag) {
          serialize_note(note, xml)
        }
      else
        serialize_note(note, xml)
      end
    end

    if (repo_note = mods.repository_note)
      xml.note(:displayLabel => repo_note.label) {
        xml.text repo_note.content
      }
    end

    mods.subjects.each do |subject|
      xml.subject(:authority => subject['source']) {
        term = subject['term'].join(" -- ")
        case subject['term_type'].first
        when 'geographic', 'cultural_context'
          xml.geographic term
        when 'temporal'
          xml.temporal term
        when 'uniform_title'
          xml.titleInfo term
        when 'genre_form', 'style_period', 'technique', 'function'
          xml.genre term
        when 'occupation'
          xml.occupation term
        else
          xml.topic term
        end
      }
    end

    mods.names.each do |name|

      case name['role']
      when 'subject'
        xml.subject {
          serialize_name(name, xml)
        }
      else
        serialize_name(name, xml)
      end
    end

    mods.parts.each do |part|
      xml.part(:ID => part['id']) {
        xml.detail {
          xml.title part['title']
        }
      }
    end

    # flattened tree
    mods.each_related_item do |item|
      xml.relatedItem(:type => 'constituent') {
        serialize_mods_inner(item, xml)
      }
    end
  end


  def serialize_name(name, xml)
    atts = {:type => name['type']}
    atts[:authority] = name['source'] if name['source']
    atts["valueURI"] = name['authority_id'] if name['authority_id']
    xml.name(atts) {
      name['parts'].each do |part|
        if part['type']
          xml.namePart(:type => part['type']) {
            xml.text part['content']
          }
        else
          xml.namePart part['content']
        end
      end
      xml.role {
        xml.roleTerm(:type => 'text', :authority => 'marcrelator') {
          xml.text name['role']
        }
      }
    }
  end


  def serialize_note(note, xml)
    atts = {}
    atts[:type] = note.type if note.type
    atts[:displayLabel] = note.label if note.label

    xml.send(note.tag, atts) {
      xml.text note.content
    }
  end

  private


  def handle_date(xml, date)
    attrs = process_date_qualifier_attrs(date)

    # if expression is provided, use that for this date
    has_expression = date.has_key?('expression') &&
                  !date['expression'].nil? &&
                  !date['expression'].empty?

    # if end specified, we need a point="end" tag.
    has_end = date.has_key?('end') &&
              !date['end'].nil? &&
              !date['end'].empty? &&
              !has_expression

    # if beginning specified, we need a point="start" tag.
    has_begin = date.has_key?('begin') &&
                !date['begin'].nil? &&
                !date['begin'].empty? &&
                !has_expression

    # the tag created depends on the type of date
    case date['label']
    when 'creation'
      type = "dateCreated"
    when 'digitized'
      type = "dateCaptured"
    when 'copyright'
      type = "copyrightDate"
    when 'modified'
      type = "dateModified"
    when 'broadcast', 'issued', 'publication'
      type = "dateIssued"
    else
      type = "dateOther"
    end

    if has_expression
      xml.send(type, attrs) { xml.text(date['expression']) }
    else
      if has_begin
        attrs.merge!({"encoding" => "w3cdtf", "keyDate" => "yes", "point" => "start"})
        xml.send(type, attrs) { xml.text(date['begin']) }
      end

      if has_end
        attrs.merge!({"encoding" => "w3cdtf", "keyDate" => "yes", "point" => "end"})
        xml.send(type, attrs) { xml.text(date['end']) }
      end
    end
  end


  def process_date_qualifier_attrs(date)
    attrs = {}

    if date.has_key?('certainty')
      case date['certainty']
      when "approximate"
        attrs["qualifier"] = "approximate"
      when "inferred"
        attrs["qualifier"] = "inferred"
      when "questionable"
        attrs["qualifier"] = "questionable"
      end
    end

    return attrs
  end

end
