class DigitalObjectComponent < Sequel::Model(:digital_object_component)
  include ASModel
  corresponds_to JSONModel(:digital_object_component)

  include Subjects
  include Extents
  include Dates
  include ExternalDocuments
  include Agents
  include Orderable
  include Notes
  include RightsStatements
  include ExternalIDs
  include FileVersions

  agent_relator_enum("linked_agent_archival_record_relators")

  orderable_root_record_type :digital_object, :digital_object_component

  set_model_scope :repository

  def validate
    validates_unique([:root_record_id, :component_id],
                     :message => "A Digital Object Component ID must be unique to its Digital Object")
    map_validation_to_json_property([:root_record_id, :component_id], :component_id)
    super
  end


  def publish_all_subrecords

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
