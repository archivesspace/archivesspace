class IndexerCommonConfig

  def self.record_types
    [
      :resource,
      :digital_object,
      :accession,
      :agent_person,
      :agent_software,
      :agent_family,
      :agent_corporate_entity,
      :subject,
      :location,
      :event,
      :top_container,
      :classification,
      :container_profile,
      :location_profile,
      :archival_object,
      :digital_object_component,
      :classification_term,
      :assessment,
      :job
    ]
  end

  def self.global_types
    [
      :agent_person,
      :agent_software,
      :agent_family,
      :agent_corporate_entity,
      :location,
      :subject
    ]
  end

  def self.resolved_attributes
    [
      'location_profile',
      'container_profile',
      'container_locations',
      'subjects',
      'places',

      # EAD export depends on this
      'linked_agents',
      'linked_records',
      'classifications',

      # EAD export depends on this
      'digital_object',
      'agent_representation',
      'repository',
      'repository::agent_representation',
      'related_agents',

      # EAD export depends on this
      'top_container',

      # EAD export depends on this
      'top_container::container_profile',

      # Assessment module depends on these
      'related_agents',
      'records',
      'collections',
      'surveyed_by',
      'reviewer',
      'creator',

      #Accessions module depends on these
      'related_accessions',

      #Container profile depends on this
      'notes',
    ]
  end

  # #build_fullrecord uses this to exclude indexing of the record property from the fullrecord field
  # this means these properties (including any embedded / sub properties) do not influence search via
  # fullrecord for the record that is being indexed
  def self.fullrecord_excludes
    [
      "created_by",
      "last_modified_by",
      "system_mtime",
      "user_mtime",
      "json",
      "types",
      "create_time",
      "date_type",
      "jsonmodel_type",
      "publish",
      "extent_type",
      "language",
      "script",
      "system_generated",
      "suppressed",
      "source",
      "rules",
      "name_order",
      "repository",
      "top_container"
    ]
  end

  def self.do_not_index
    # ANW-1065
    # #sanitize_json uses this hash to clean up sensitive data, preventing it from being indexed.
    # It does this by mutating the record being indexed, removing the data so it is not available
    # in the json field or to the fullrecord field when that is built
    {
        "agent_person"           => {:location => [],
                                     :to_clean => "agent_contacts"},
        "agent_family"           => {:location => [],
                                     :to_clean => "agent_contacts"},
        "agent_corporate_entity" => {:location => [],
                                     :to_clean => "agent_contacts"},
        "agent_software"         => {:location => [],
                                     :to_clean => "agent_contacts"},
    }
  end
end
