class DigitalObject < Sequel::Model(:digital_object)
  include ASModel
  corresponds_to JSONModel(:digital_object)

  include AutoGenerator
  include Subjects
  include Extents
  include LangMaterials
  include Dates
  include Classifications
  include ExternalDocuments
  include Agents
  include Trees
  include DigitalObjectTrees
  include Notes
  include RightsStatements
  include ExternalIDs
  include FileVersions
  include CollectionManagements
  include MetadataRights
  include UserDefineds
  include ComponentsAddChildren
  include Events
  include Publishable
  include Assessments::LinkedRecord
  include RepresentativeFileVersion
  include TouchRecords

  enable_suppression

  agent_role_enum("linked_agent_role")
  agent_relator_enum("linked_agent_archival_record_relators")

  tree_record_types :digital_object, :digital_object_component
  tree_of(:digital_object, :digital_object_component)

  set_model_scope :repository

  define_relationship(:name => :instance_do_link,
                      :contains_references_to_types => proc {[Instance]})


  auto_generate :property => :slug,
                :generator => proc { |json|
                  if AppConfig[:use_human_readable_urls]
                    if json["is_slug_auto"]
                      AppConfig[:auto_generate_slugs_with_id] ?
                        SlugHelpers.id_based_slug_for(json, DigitalObject) :
                        SlugHelpers.name_based_slug_for(json, DigitalObject)
                    else
                      json["slug"]
                    end
                  end
                }

  repo_unique_constraint(:digital_object_id,
                         :message => "Must be unique",
                         :json_property => :digital_object_id)

  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    relationships = find_relationship(:instance_do_link).find_by_participant_ids(self, objs.map(&:id))
    instances = Instance.filter(:id => relationships.map {|relationship| relationship[:instance_id]}).all

    relationship_to_instance = Hash[relationships.map {|relationship|
                                      [relationship, instances.select {|instance| relationship[:instance_id] == instance.id}]
                                    }]

    jsons.zip(objs).each do |json, obj|
      json["collection"] = []
      json["linked_instances"] = []

      relationships.each do |relationship|
        next unless relationship.relates_to?(obj)

        instances = relationship_to_instance[relationship]

        instances.each do |link|
          uri = self.uri_for(:resource, link[:resource_id]) if link[:resource_id]
          uri = self.uri_for(:archival_object, link[:archival_object_id]) if link[:archival_object_id]
          uri = self.uri_for(:accession, link[:accession_id]) if link[:accession_id]

          if uri.nil?
            raise "Digital Object Instance not linked to either a resource, archival object or accession"
          end

          if link[:archival_object_id]
            archival_object = ArchivalObject.find(id: link[:archival_object_id])

            # ANW-1703: only include resource uri from AO if the AO is published. Publish will be 0|1
            if archival_object.publish.positive?
              json["collection"] << {"ref" => self.uri_for(:resource, archival_object.root_record_id)}
            end
          else
            json["collection"] << {"ref" => uri}
          end

          json["linked_instances"].push({"ref" => uri})
        end
      end

      json["collection"].uniq!
    end

    jsons
  end

  def self.instance_owners_root_records(id)
    relationships = self.find_relationship(:instance_do_link).find_by_participant(self[id])
    resource_ids = Instance.inner_join(:archival_object, archival_object__id: :instance__archival_object_id)
                     .filter(instance__id: relationships.map {|relationship| relationship[:instance_id]})
                     .map { |row| row[:root_record_id] }
    resource_ids
  end

  def self.touch_records(obj)
    [
      { type: Resource, ids: DigitalObject.instance_owners_root_records(obj.id) }
    ]
  end

  def delete
    instance_subrecords = related_records(:instance_do_link)
    super
    instance_subrecords.each {|sub| sub.delete }
  end
end
