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
            digital_object = DigitalObject.to_jsonmodel(id, opts)
            if digital_object["representative_file_version"]
              json["representative_file_version"] = digital_object["representative_file_version"].merge({"digital_object" => digital_object.uri})
            end
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

        # if we still don't have a representative and are dealing with a record type
        # that has a tree under it, we will now look in the tree

        if json["representative_file_version"].nil? && self.name == "DigitalObject"

          digital_object_component_set = DigitalObjectComponent
                                           .left_join(:file_version, digital_object_component_id: :digital_object_component__id)
                                           .filter(root_record_id: json.id)
                                           .select(Sequel.as(:digital_object_component__id, :digital_object_component_id),
                                                   Sequel.as(:digital_object_component__parent_id, :digital_object_component_parent_id),
                                                   Sequel.as(:digital_object_component__position, :digital_object_component_position),
                                                   Sequel.as(:file_version__id, :file_version_id),
                                                   Sequel.as(:file_version__publish, :file_version_publish),
                                                   Sequel.as(:file_version__use_statement_id, :file_version_use_statement_id),
                                                   Sequel.as(:file_version__is_representative, :file_version_is_representative))
                                           .order(:digital_object_component_position)

          if (digital_object_component_id = find_representative_in_digital_object_tree(digital_object_component_set))
            json["representative_file_version"] = DigitalObjectComponent.to_jsonmodel(digital_object_component_id, opts)['representative_file_version']
          end
        end

        if json["representative_file_version"].nil? && self.name == "Resource"

          archival_object_set = ArchivalObject
                                  .left_join(:instance, :archival_object_id => :archival_object__id)
                                  .left_join(:instance_do_link_rlshp, :instance_id => :instance__id)
                                  .left_join(:digital_object, :id => :instance_do_link_rlshp__digital_object_id)
                                  .filter(root_record_id: json.id)
                                  .select(Sequel.as(:archival_object__id, :archival_object_id),
                                          Sequel.as(:archival_object__position, :archival_object_position),
                                          Sequel.as(:archival_object__parent_id, :archival_object_parent_id),
                                          Sequel.as(:digital_object__id, :digital_object_id),
                                          Sequel.as(:instance__is_representative, :digital_object_is_representative))
                                  .order(:archival_object_position)

          if (digital_object_id = find_representative_in_resource_tree(archival_object_set))
            json["representative_file_version"] = DigitalObject.to_jsonmodel(digital_object_id, opts)['representative_file_version']
          end
        end
      end
      jsons
    end

    private

    def thumbnail_use_statement_id
      use_statement_enum_id = Enumeration.find(name: "file_version_use_statement").id
      thumbnail_use_statement_id = EnumerationValue.find(enumeration_id: use_statement_enum_id, value: "image-thumbnail").id
      thumbnail_use_statement_id
    end

    # this is an expensive operation for large trees with no representative.
    # perhaps there is a way to do this without iterating through query results?
    def find_representative_in_resource_tree(record_set, parent_id = nil)
      same_parent_set = record_set.filter(archival_object__parent_id: parent_id)
      return nil if same_parent_set.count == 0

      same_parent_set.each do |row|
        # does this node have a representative?
        if row[:digital_object_id] && row[:digital_object_is_representative]
          return row[:digital_object_id]
        end

        # does this node have a descendent with a representative?
        if (result = find_representative_in_resource_tree(record_set, row[:archival_object_id]))
          return result
        end
      end

      # we went through the tree and didn't find anything
      return nil
    end

    def find_representative_in_digital_object_tree(record_set, parent_id = nil, pocket=[])
      return nil if record_set.count == 0
      same_parent_set = record_set.filter(digital_object_component__parent_id: parent_id)
      return nil if same_parent_set.count == 0

      same_parent_set.each do |row|
        if row[:file_version_publish]
          if row[:file_version_is_representative]
            return row[:digital_object_component_id]
          elsif (pocket.length < 2) && (row[:file_version_use_statement_id] == thumbnail_use_statement_id)
            pocket << row[:digital_object_component_id]
          elsif pocket.empty?
            pocket << row[:digital_object_component_id]
          end
        end

        if (result = find_representative_in_digital_object_tree(record_set, row[:digital_object_component_id], pocket))
          return result
        end
      end

      # fall back to any published thumbnail, or just anything published
      if pocket.length > 0
        return pocket.last
      else
        return nil
      end
    end

  end
end
