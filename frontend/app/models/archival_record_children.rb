class ArchivalRecordChildren < JSONModel(:archival_record_children)

  attr_accessor :uri

  def self.uri_for(*args)
    nil
  end

  def self.from_hash(hash, raise_errors = true, trusted = false)

    hash["children"].each do |child|

      # clean up dates
      if child["dates"][0].reject{|k,v| v.blank?}.empty?
        child.delete("dates")
      else
        child["dates"][0]["label"] = "other"
      end

      # clean up instances
      if child["instances"][0]["container"].reject{|k,v| v.blank?}.empty?
        child["instances"][0].delete("container")
      end
      if !child["instances"][0].has_key?("container") and child["instances"][0]["instance_type"].blank?
        child.delete("instances")
      end

      # clean up notes
      (0..2).each do |i|
        if not child["notes"][i]["type"].blank?
          [:note_bibliography, :note_index, :note_singlepart, :note_multipart].each do |notetype|
            if JSONModel.enum_values(JSONModel(notetype).schema['properties']['type']['dynamic_enum']).include?(child["notes"][i]["type"])
              child["notes"][i]["jsonmodel_type"] = notetype.to_s
            end
          end

          child["notes"][i]["publish"] = true

          # Multipart and biog/hist notes use a 'text' subnote type for their content.
          if ['note_multipart', 'note_bioghist'].include?(child["notes"][i]["jsonmodel_type"])
            child["notes"][i]["subnotes"] = [{"jsonmodel_type" => "note_text",
                                               "content" => child["notes"][i]["content"].join(" ")}]
          end

        elsif child["notes"][i]["type"].blank? and child["notes"][i]["content"][0].blank?
          child["notes"][i] = nil
        end
      end
      child["notes"].compact!
    end

    super
  end
end
