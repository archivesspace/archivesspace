module RecordChildren

  def self.included(base)
    base.extend(ClassMethods)
  end

  def child_type
    self.class.child_type
  end

  module ClassMethods

    def child_type
      JSONModel.parse_jsonmodel_ref(self.schema['properties']['children']['items']['type']).first
    end


    def note_types_for_child
      JSONModel(child_type).schema['properties']['notes']['items']['type'].map {|ref|
        JSONModel.parse_jsonmodel_ref(ref['type']).first
      }
    end

    def clean_dates(child)
      if child["dates"]
        if child["dates"][0].reject{|k,v| v.blank?}.empty?
          child.delete("dates")
        elsif child["dates"][0]["label"].empty?
          child["dates"][0]["label"] = "other"
        end
      end
    end

    def clean_notes(child)
      if child["notes"]
        (0..2).each do |i|
          if not child["notes"][i]["type"].blank?
            note_types_for_child.each do |notetype|
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
    end

    def clean(child)
      clean_dates(child)
      clean_notes(child)
    end

    def from_hash(hash, raise_errors = true, trusted = false)
      hash["children"].each {|child| clean(child)}

      super
    end

  end
end
