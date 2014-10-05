require_relative 'marcxml_converter'

class MarcXMLAccessionConverter < MarcXMLConverter
  def self.import_types(show_hidden = false)
    [
     {
       :name => "marcxml_accession",
       :description => "Import MARC XML records as Accessions"
     }
    ]
  end

  def self.instance_for(type, input_file)
    if type == "marcxml_accession"
      self.new(input_file)
    else
      nil
    end
  end

end

MarcXMLAccessionConverter.configure do |config|
  config["/record"][:obj] = :accession
  config["/record"][:map].delete("//controlfield[@tag='008']")

  config["/record"][:map]["self::record"] = -> accession, node {

    if !accession.title && accession['_fallback_titles'] && !accession['_fallback_titles'].empty?
      accession.title = accession['_fallback_titles'].shift
    end

    if accession.id_0.nil? or accession.id.empty?
      accession.id_0 = "imported-#{SecureRandom.uuid}"
    end

    accession.accession_date = Time.now.to_s.sub(/\s.*/, '')
  }


  ["datafield[@tag='210']", "datafield[@tag='222']", "datafield[@tag='240']", "datafield[@tag='242']", "datafield[@tag='246'][@ind2='0']",  "datafield[@tag='250']", "datafield[@tag='254']", "datafield[@tag='255']", "datafield[@tag='257']", "datafield[@tag='258']", "datafield[@tag='260']",  "datafield[@tag='340']", "datafield[@tag='342']", "datafield[@tag='351']", "datafield[@tag='352']", "datafield[@tag='355']", "datafield[@tag='357']",  "datafield[@tag='500']", "datafield[@tag='501']", "datafield[@tag='502']", "datafield[@tag='506']", "datafield[@tag='507']", "datafield[@tag='508']",  "datafield[@tag='511']", "datafield[@tag='513']", "datafield[@tag='514']", "datafield[@tag='518']", "datafield[@tag='520'][@ind1!='3' and @ind1!='8']",  "datafield[@tag='521'][@ind1!='8']",  "datafield[@tag='522']", "datafield[@tag='524']",  "datafield[@tag='530']", "datafield[@tag='533']",  "datafield[@tag='534']", "datafield[@tag='535']", "datafield[@tag='538']", "datafield[@tag='540']", "datafield[@tag='541']", "datafield[@tag='544']",  "datafield[@tag='545']", "datafield[@tag='561']", "datafield[@tag='562']", "datafield[@tag='563']", "datafield[starts-with(@tag, '59')]",  "datafield[@tag='740']", "datafield[@tag='256']", "datafield[@tag='306']", "datafield[@tag='343']", "datafield[@tag='520'][@ind1='3']", "datafield[@tag='546']", "datafield[@tag='565']", "datafield[@tag='504']", "datafield[@tag='510']", "datafield[@tag='581']"].each do |note_making_path|
    config["/record"][:map].delete(note_making_path)
  end

  config["/record"][:map]["datafield[@tag='506']"] = -> record, node {
    node.xpath("subfield").each do |sf|
      val = sf.inner_text
      unless val.empty?
        record.access_restrictions_note ||= ""
        record.access_restrictions_note += " " unless record.access_restrictions_note.empty?
        record.access_restrictions_note += val
      end
    end

    if node.attr('ind1') == '1'
      record.access_restrictions = true
    end

  }


  config["/record"][:map]["datafield[@tag='520']"] = -> record, node {
    node.xpath("subfield").each do |sf|
      val = sf.inner_text
      unless val.empty?
        record.content_description ||= ""
        record.content_description += " " unless record.content_description.empty?
        record.content_description += val
      end
    end
  }


  config["/record"][:map]["datafield[@tag='540']"] = -> record, node {
    node.xpath("subfield").each do |sf|
      val = sf.inner_text
      unless val.empty?
        record.use_restrictions_note ||= ""
        record.use_restrictions_note += " " unless record.use_restrictions_note.empty?
        record.use_restrictions_note += val
      end
    end

    record.use_restrictions = true
  }


  config["/record"][:map]["datafield[@tag='541']"] = -> record, node {
    provenance1 = ""

    node.xpath("subfield").each do |sf|
      val = sf.inner_text

      unless val.empty?
        provenance1 += " " unless provenance1.empty?
        provenance1 += val
      end
    end

    if record.provenance
      record.provenance = provenance1 + " #{record.provenance}"
    elsif provenance1.length > 0
      record.provenance = provenance1
    end
  }


  config["/record"][:map]["datafield[@tag='561']"] = -> record, node {
    provenance2 = ""

    node.xpath("subfield").each do |sf|
      val = sf.inner_text

      unless val.empty?
        provenance2 += " " unless provenance2.empty?
        provenance2 += val
      end
    end

    if record.provenance
      record.provenance = "#{record.provenance} "  + provenance2
    elsif provenance2.length > 0
      record.provenance = provenance2
    end
  }

end
