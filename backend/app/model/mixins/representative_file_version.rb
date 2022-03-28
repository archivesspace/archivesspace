# mixin for archival records that
# need a computed "representative file version" for
# banner images and thumbnails in public interface etc.

module RepresentativeFileVersion

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods

    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super
      jsons.each do |json|
        case self.name
        when "Resource", "Accession", "ArchivalObject"
          if representative_instance = json.instances.select {|i| i["is_representative"] == true && i["instance_type"] == "digital_object" }.first
            id = JSONModel(:digital_object).id_for(representative_instance["digital_object"]["ref"])
            json["representative_file_version"] = DigitalObject.to_jsonmodel(id)["representative_file_version"]
          end
          if json["representative_file_version"].nil? && representative_instance
            DigitalObjectComponent.filter(:root_record_id => id).select(:id).each do |row|
              # unlikely to scale when the tree is large
              if rep_fv = DigitalObjectComponent.to_jsonmodel(row[:id])["representative_file_version"]
                json["representative_file_version"] = rep_fv
                break
              end
            end
          end

        when "DigitalObject", "DigitalObjectComponent"
          # Compute representative_file_version property, ANW-1493
          fvs = json[:file_versions]

          published_representative_fv = fvs.select { |fv| (fv["publish"] == true || fv["publish"] == 1) && (fv["is_representative"] == true || fv["is_representative"] == 1) }

          published_image_thumbnail_fvs = fvs.select { |fv| (fv["publish"] == true || fv["publish"] == 1) && fv["is_representative"] != true && fv["is_representative"] != 1 && fv["use_statement"] == 'image-thumbnail' }

          published_fvs = fvs.select { |fv| (fv["publish"] == true || fv["publish"] == 1) && fv["is_representative"] != true && fv["is_representative"] != 1 && fv["use_statement"] != 'image-thumbnail' }

          if published_representative_fv.count > 0
            json["representative_file_version"] = published_representative_fv.first
          elsif published_image_thumbnail_fvs.count > 0
            json["representative_file_version"] = published_image_thumbnail_fvs.first
          elsif published_fvs.count > 0
            json["representative_file_version"] = published_fvs.first
          end
        end

        # this could get very ugly
        if json["representative_file_version"].nil? && self.name == "Resource"
          ArchivalObject.filter(:root_record_id => json.id).select(:id).each do |row|
            if rep_fv = ArchivalObject.to_jsonmodel(row[:id])["representative_file_version"]
              json["representative_file_version"] = rep_fv
              break
            end
          end
        end
      end

      jsons
    end
  end
end
