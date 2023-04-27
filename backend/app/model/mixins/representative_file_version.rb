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
              json["representative_file_version"] = digital_object["representative_file_version"]
                                                      .merge("derived_from" => digital_object.uri)
                                                      .reject { |k, _| k == "link_uri" }
            else
              digital_object_component_set = DigitalObjectComponent
                                               .left_join(:file_version, digital_object_component_id: :digital_object_component__id)
                                               .filter(root_record_id: digital_object.id)
                                               .select(Sequel.as(:digital_object_component__id, :digital_object_component_id),
                                                       Sequel.as(:digital_object_component__parent_id, :digital_object_component_parent_id),
                                                       Sequel.as(:digital_object_component__position, :digital_object_component_position),
                                                       Sequel.as(:file_version__id, :file_version_id),
                                                       Sequel.as(:file_version__publish, :file_version_publish),
                                                       Sequel.as(:file_version__use_statement_id, :file_version_use_statement_id),
                                                       Sequel.as(:file_version__is_representative, :file_version_is_representative))
                                               .order(:digital_object_component_position)

              if (digital_object_component_id = find_representative_in_digital_object_tree(digital_object_component_set))
                digital_object_component = DigitalObjectComponent.to_jsonmodel(digital_object_component_id, opts)
                if digital_object_component['representative_file_version']
                  json['representative_file_version'] = digital_object_component['representative_file_version'].merge("derived_from" => digital_object_component.uri)
                end
              end
            end
          end
        when "DigitalObject", "DigitalObjectComponent"
          fvs = json[:file_versions]
          fv_pairs = []
          last_pair = nil
          fvs.each do |fv|
            # all done if:
            break if fv_pairs[0] && fv_pairs[0].size == 2
            # ANW-1721 - if the fv in last_pair ends up being selected, this will be its link target
            if (last_pair && last_pair.size == 1)
              last_pair << fv
            end
            # ANW-1209 REQ-3
            if fv_pairs[0].nil? && fv["publish"] && fv["is_representative"]
              last_pair = fv_pairs[0] = [fv]
            # ANW-1209 REQ-3.1
            elsif fv_pairs[1].nil? && fv["publish"] && fv["use_statement"] == 'image-thumbnail'
              last_pair = fv_pairs[1] = [fv]
            # The older logic for selecting an image to show via `process_file_versions`
            # in public/app/controllers/concerns/result_info.rb
            elsif fv_pairs[2].nil? && fv["publish"] \
              && fv["file_uri"].start_with?('http') && fv["xlink_show_attribute"] == 'embed'

              last_pair = fv_pairs[2] = [fv]
            end
          end
          # now we select the best candidate pair based on order
          if (fvp = fv_pairs.compact.first)
            json["representative_file_version"] = fvp[0]
            if fvp[1] && fvp[1]["publish"]
              json["representative_file_version"]["link_uri"] = fvp[1]["file_uri"]
            end
          end

        end

        # if we still don't have a representative and are dealing with a Resource
        # that has a tree under it, we will now look in the tree
        if json["representative_file_version"].nil? && self.name == "Resource"

          archival_object_set = ArchivalObject
                                  .left_join(:instance, :archival_object_id => :archival_object__id)
                                  .left_join(:instance_do_link_rlshp, :instance_id => :instance__id)
                                  .left_join(:digital_object, :id => :instance_do_link_rlshp__digital_object_id)
                                  .filter(archival_object__root_record_id: json.id)
                                  .filter(archival_object__publish: true)
                                  .select(Sequel.as(:archival_object__id, :archival_object_id),
                                          Sequel.as(:archival_object__position, :archival_object_position),
                                          Sequel.as(:archival_object__parent_id, :archival_object_parent_id),
                                          Sequel.as(:digital_object__id, :digital_object_id),
                                          Sequel.as(:instance__is_representative, :digital_object_is_representative))
                                  # .order(:archival_object_position)

          if (digital_object_id = find_representative_in_resource_tree(archival_object_set))
            digital_object = DigitalObject.to_jsonmodel(digital_object_id, opts)
            if digital_object["representative_file_version"]
              json["representative_file_version"] = digital_object['representative_file_version'].merge("derived_from" => digital_object.uri)
            else
              digital_object_component_set = DigitalObjectComponent
                                               .left_join(:file_version, digital_object_component_id: :digital_object_component__id)
                                               .filter(root_record_id: digital_object.id)
                                               .select(Sequel.as(:digital_object_component__id, :digital_object_component_id),
                                                       Sequel.as(:digital_object_component__parent_id, :digital_object_component_parent_id),
                                                       Sequel.as(:digital_object_component__position, :digital_object_component_position),
                                                       Sequel.as(:file_version__id, :file_version_id),
                                                       Sequel.as(:file_version__publish, :file_version_publish),
                                                       Sequel.as(:file_version__use_statement_id, :file_version_use_statement_id),
                                                       Sequel.as(:file_version__is_representative, :file_version_is_representative))
                                               .order(:digital_object_component_position)

              if (digital_object_component_id = find_representative_in_digital_object_tree(digital_object_component_set))
                digital_object_component = DigitalObjectComponent.to_jsonmodel(digital_object_component_id, opts)
                if digital_object_component['representative_file_version']
                  json['representative_file_version'] = digital_object_component['representative_file_version'].merge("derived_from" => digital_object_component.uri)
                end
              end
            end
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

    def find_representative_in_resource_tree(record_set, parent_id = nil)
      id_positions = {nil => 0}
      id_depths = {nil => 0}
      parent_to_child_id = {}
      id_digital_objects = {}

      record_set.each do |row|
        child_id = row[:archival_object_id]
        position = row[:archival_object_position]
        parent_id = row[:archival_object_parent_id]
        id_positions[child_id] ||= position
        parent_to_child_id[parent_id] ||= []
        parent_to_child_id[parent_id] << child_id
        if row[:digital_object_id] && row[:digital_object_is_representative]
          id_digital_objects[child_id] = row[:digital_object_id]
        end
      end

      root_set = [nil]

      while !root_set.empty?
        next_rec = root_set.shift
        if id_digital_objects[next_rec]
          return id_digital_objects[next_rec]
        end

        children = parent_to_child_id.fetch(next_rec, []).uniq.sort_by {|child| id_positions[child]}
        children.reverse.each do |child|
          id_depths[child] = id_depths[next_rec] + 1
          root_set.unshift(child)
        end
      end
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
