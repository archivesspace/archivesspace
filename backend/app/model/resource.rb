class Resource < Sequel::Model(:resource)
  include ASModel
  corresponds_to JSONModel(:resource)

  include Identifiers
  include Subjects
  include Extents
  include Dates
  include ExternalDocuments
  include RightsStatements
  include Instances
  include Deaccessions
  include Agents
  include Trees
  include Notes
  include Relationships
  include ExternalIDs
  include CollectionManagements
  include UserDefineds
  include ComponentsAddChildren

  orderable_root_record_type :resource, :archival_object

  agent_relator_enum("linked_agent_archival_record_relators")

  tree_of(:resource, :archival_object)
  set_model_scope :repository

  define_relationship(:name => :spawned,
                      :json_property => 'related_accessions',
                      :contains_references_to_types => proc {[Accession]})

  define_relationship(:name => :classification,
                      :json_property => 'classification',
                      :contains_references_to_types => proc {[Classification,
                                                              ClassificationTerm]},
                      :is_array => false)

  def validate
    validates_unique([:repo_id, :ead_id], :message => "Must be unique")

    map_validation_to_json_property([:repo_id, :ead_id], :ead_id)

    super
  end


  def publish_all_subrecords_and_components

    # publish all archival object children
    children = ArchivalObject.filter(:root_record_id => self.id)
    if not children.empty?
      children.each do |ao|
        ao.publish_all_subrecords
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
