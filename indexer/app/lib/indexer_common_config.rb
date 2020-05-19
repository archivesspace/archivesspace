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

      'creator'
    ]
  end

  def self.do_not_index
    # ANW-1065
    # #sanitize_json uses this hash to clean up sensitive data, preventing it from being indexed in the json field in the indexer doc.
    # the first 3 entries will set json["agent_contacts"] to [] for agent_person, corp, etc records
    # the last entry will set json["agent_representation"]["_resolved"]["agent_contacts"] for repository records
    {  
        "agent_person"           => {:location => [], 
                                     :to_clean => "agent_contacts"}, 
        "agent_family"           => {:location => [],
                                     :to_clean => "agent_contacts"},
        "agent_corporate_entity" => {:location => [],
                                     :to_clean => "agent_contacts"},
        "agent_software"         => {:location => [],
                                     :to_clean => "agent_contacts"},
        "repository"             => {:location => ["agent_representation", 
                                                   "_resolved"],
                                     :to_clean => "agent_contacts"},
        "resource"               => {:location => ["repository",
                                                   "_resolved",
                                                   "agent_representation", 
                                                   "_resolved"],
                                     :to_clean => "agent_contacts"},
        "archival_object"        => {:location => ["repository",
                                                   "_resolved",
                                                   "agent_representation", 
                                                   "_resolved"],
                                     :to_clean => "agent_contacts"},
        "digital_object"         => {:location => ["repository",
                                                   "_resolved",
                                                   "agent_representation", 
                                                   "_resolved"],
                                     :to_clean => "agent_contacts"},
        "digital_object_component" => {:location => ["repository",
                                                   "_resolved",
                                                   "agent_representation", 
                                                   "_resolved"],
                                     :to_clean => "agent_contacts"},
        "accession"              => {:location => ["repository",
                                                   "_resolved",
                                                   "agent_representation", 
                                                   "_resolved"],
                                     :to_clean => "agent_contacts"},
    }

  end
end
