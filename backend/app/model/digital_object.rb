class DigitalObject < Sequel::Model(:digital_object)
  include ASModel
  corresponds_to JSONModel(:digital_object)

  include Subjects
  include Extents
  include Dates
  include ExternalDocuments
  include Agents
  include Trees
  include Notes
  include RightsStatements
  include ExternalIDs
  include FileVersions
  include CollectionManagements
  include UserDefineds

  agent_relator_enum("linked_agent_archival_record_relators")

  tree_of(:digital_object, :digital_object_component)
  set_model_scope :repository

  define_relationship(:name => :instance_do_link,
                      :contains_references_to_types => proc {[Instance]})


  def self.sequel_to_jsonmodel(obj, opts = {})
    json = super

    json["linked_instances"] = []

    obj.linked_records(:instance_do_link).each do |link|
      json["linked_instances"].push({
          "ref" => link.resource ? link.resource.uri : link.archival_object.uri 
      })
    end

    json
  end


  def publish_all_subrecords_and_components

    # publish all components
    components = DigitalObjectComponent.filter(:root_record_id => self.id)
    if not components.empty?
      components.each do |component|
        component.publish_all_subrecords
      end
    end

    # publish all notes
    notes = ASUtils.json_parse(self.notes || "[]")
    if not notes.empty?
      notes.each do |note|
        note["publish"] = true
      end
      self.notes = JSON(notes)
    end

    # publish all file versions
    self.file_version.each do |file|
      file.publish = 1
      file.save
    end

    # publish all external documents
    self.external_document.each do |exdoc|
      exdoc.publish = 1
      exdoc.save
    end

    # set our own publish to true
    self.publish = 1

    # save
    self.save

  end

end
