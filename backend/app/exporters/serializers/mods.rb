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

    xml.mods(root_args){
      serialize_mods_inner(mods, xml)
    }
  end



  def serialize_mods_inner(mods, xml)

    xml.titleInfo {
      xml.title mods.title
    }

    xml.identifier mods.identifier

    xml.typeOfResource mods.type_of_resource


    xml.language {
      xml.languageTerm(:type => 'text', :authority => 'iso639-2b') {
        xml.text mods.language_term
      }
    }

    mods.dates.each do |date|
      attrs = process_date_attrs(date)
      case date['label']
      when 'creation'
        xml.dateCreated(attrs) { xml.text(process_date_string(date)) }
      when 'digitized'
        xml.dateCaptured(attrs) { xml.text(process_date_string(date)) }
      when 'copyright'
        xml.copyrightDate(attrs) { xml.text(process_date_string(date)) }
      when 'modified'
        xml.dateModified(attrs) { xml.text(process_date_string(date)) }
      when 'broadcast', 'issued', 'publication'
        xml.dateIssued(attrs) { xml.text(process_date_string(date)) }
      else 
        xml.dateOther(attrs) { xml.text(process_date_string(date)) }
      end
    end

    xml.physicalDescription{
      mods.extents.each do |extent|
        xml.extent extent
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
        when 'genre_form', 'style_period'
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

  def process_date_string(date)
    # use date expression, if present
    unless date['expression'].nil? || date['expression'].empty?
      return date['expression']
    end

    # if end date specified, use begin - end form
    unless date['end'].nil? || date['end'].empty?
      return "#{date['begin']} - #{date['end']}"

    # otherwise, just use begin date
    else
      return date['begin']
    end
  end

  def process_date_attrs(date)
    attrs = {}

    # qualifier
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
    # encoding
    attrs['encoding'] = "w3cdtf"

    # keyDate
    attrs['keyDate'] = "yes"

    # point
    attrs['point'] = "end"

    return attrs
  end

end
