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


  # strip mappings that target .notes
  config["/record"][:map].each do |path, defn|
    next unless defn.is_a?(Hash)
    if defn[:rel] == :notes
      config["/record"][:map].delete(path)
    end
  end


  # strip other mappings that target resource-only properties
  [
   "datafield[@tag='536']" # finding_aid_sponsor
  ].each do |resource_only_path|
    config["/record"][:map].delete(resource_only_path)
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
