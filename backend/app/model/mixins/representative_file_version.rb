# This module calculates and applies if possible a read-only #representative_file_version
# property to the following Record Types: DigitalObject, DigitalObjectComponent, Accession,
# Resource and ArchivalObject. It is intended to encapsulate all the logic for how
# representations are selected and displayed per the specification referenced here:
#
# https://archivesspace.atlassian.net/browse/ANW-1209
#
# The key fields for determining whether a file_version can appear as a representative_file_version
# of a parent DigitalObject or DigitalObjectComponent are:
#    Boolean file_version.publish
#    Boolean file_version.is_representative
#    String file_version.use_statement
#
# The other three record types determine their representative by looking for an Instance sub-record
# that a) links to a DigitalObject; and b) has `is_representative` set to true.
#
# This implementation  does not prevent a user from selecting a DigtalObject as an .is_representative
# Instance, even if the DigitalObject does not have any published FileVersion subrecords. Perhaps
# additional validation rules to prevent that scenario will be desired.
#
# Finally, a DigitalObject can fall back to a descendent DigitalObjectComponent's representative file version
# if necessary, and a Resource can fall back to a descendent ArchivalObject's representative file version.
#
# We assume the following constraints, which are implemented on DigitalObject and DigitalObjectComponent models:
#
# 1) digital_object(_component) cannot have more than one file_version where .is_representative is true"
# 2) file_version.is_representative cannot be true unless .publish is true
#
# This could be optimized such that the json objects are only augmented with this field when the request is coming
# from the indexer.

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
            json["representative_file_version"] = DigitalObject.to_jsonmodel(id, opts)["representative_file_version"]
          end
        when "DigitalObject", "DigitalObjectComponent"
          fvs = json[:file_versions]

          published_representative_fv = fvs.select { |fv| (fv["publish"] == true || fv["publish"] == 1) \
            && (fv["is_representative"] == true || fv["is_representative"] == 1) }

          published_image_thumbnail_fvs = fvs.select { |fv| (fv["publish"] == true || fv["publish"] == 1) \
            && fv["is_representative"] != true \
            && fv["is_representative"] != 1 && fv["use_statement"] == 'image-thumbnail' }

          if published_representative_fv.count > 0
            json["representative_file_version"] = published_representative_fv.first
          elsif published_image_thumbnail_fvs.count > 0
            json["representative_file_version"] = published_image_thumbnail_fvs.first
          else
            # published_fvs = fvs.select { |fv| (fv["publish"] == true || fv["publish"] == 1) \
            #   && fv["is_representative"] != 1 \
            #   && (fv["use_statement"] == 'image-service' || %w(jpeg gif).include?(fv['file_format_name']))
            # }
            published_fvs = fvs.select { |fv| (fv["publish"] == true || fv["publish"] == 1) && fv["is_representative"] != 1 }

            json["representative_file_version"] = published_fvs.first
          end
        end

        if json["representative_file_version"].nil? && self.name == "DigitalObject"
          file_version_set = DigitalObject
                               .inner_join(:digital_object_component, root_record_id: :digital_object__id)
                               .inner_join(:file_version, digital_object_component_id: :digital_object_component__id)
                               .filter(root_record_id: json.id)
                               .filter(file_version__publish: true)
                               .filter(:file_version__id)
                               .select(Sequel.as(:file_version__id, :file_version_id),
                                       Sequel.as(:file_version__is_representative, :file_version_is_representative))
          unless (file_version_set.empty?)
            file_version_id = file_version_set
                                .order(:file_version_is_representative)
                                .reverse
                                .first[:file_version_id]
            json["representative_file_version"] = FileVersion.to_jsonmodel(file_version_id)
          end

        end

        if json["representative_file_version"].nil? && self.name == "Resource"
          digital_object_set = ArchivalObject
                                 .inner_join(:instance, :archival_object_id => :archival_object__id)
                                 .inner_join(:instance_do_link_rlshp, :instance_id => :instance__id)
                                 .inner_join(:digital_object, :id => :instance_do_link_rlshp__digital_object_id)
                                 .filter(root_record_id: json.id)
                                 .filter(instance__is_representative: true)
                                 .select(Sequel.as(:digital_object__id, :digital_object_id),
                                         Sequel.as(:archival_object__position, :archival_object_position))

          unless (digital_object_set.empty?)
            digital_object_id = digital_object_set
                                  .order(:archival_object_position)
                                  .first[:digital_object_id]

            json["representative_file_version"] = DigitalObject.to_jsonmodel(digital_object_id, opts)['representative_file_version']
          end
        end
      end
      jsons
    end
  end
end
