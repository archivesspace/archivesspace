class DigitalObject < Sequel::Model(:digital_object)
  include ASModel
  corresponds_to JSONModel(:digital_object)

  include Subjects
  include Extents
  include Dates
  include ExternalDocuments
  include Agents
  include Trees
  include DigitalObjectTrees
  include Notes
  include RightsStatements
  include ExternalIDs
  include FileVersions
  include CollectionManagements
  include UserDefineds
  include ComponentsAddChildren
  include Events
  include Publishable
  include Assessments::LinkedRecord

  enable_suppression

  agent_role_enum("linked_agent_role")
  agent_relator_enum("linked_agent_archival_record_relators")

  tree_record_types :digital_object, :digital_object_component
  tree_of(:digital_object, :digital_object_component)

  set_model_scope :repository

  define_relationship(:name => :instance_do_link,
                      :contains_references_to_types => proc {[Instance]})


  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    relationships = find_relationship(:instance_do_link).find_by_participant_ids(self, objs.map(&:id))
    instances = Instance.filter(:id => relationships.map {|relationship| relationship[:instance_id]}).all

    relationship_to_instance = Hash[relationships.map {|relationship|
                                      [relationship, instances.select {|instance| relationship[:instance_id] == instance.id}]
                                    }]

    jsons.zip(objs).each do |json, obj|
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

          json["linked_instances"].push({"ref" => uri})
        end
      end
    end

    jsons
  end

  def delete
    related_records(:instance_do_link).map {|sub| sub.delete }
    super
  end


  repo_unique_constraint(:digital_object_id,
                         :message => "Must be unique",
                         :json_property => :digital_object_id)

end
