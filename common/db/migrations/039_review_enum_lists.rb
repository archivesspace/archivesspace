require_relative 'utils'


REVIEWED_LIST = {"accession_acquisition_type"=>"1", "accession_parts_relator"=>"0", "accession_parts_relator_type"=>"1", "accession_resource_type"=>"1", "accession_sibling_relator"=>"0", "accession_sibling_relator_type"=>"1", "agent_contact_salutation"=>"1", "agent_relationship_associative_relator"=>"0", "agent_relationship_earlierlater_relator"=>"0", "agent_relationship_parentchild_relator"=>"0", "agent_relationship_subordinatesuperior_relator"=>"0", "archival_record_level"=>"0", "collection_management_processing_priority"=>"1", "collection_management_processing_status"=>"1", "container_location_status"=>"0", "container_type"=>"1", "country_iso_3166"=>"0", "date_calendar"=>"1", "date_certainty"=>"0", "date_era"=>"1", "date_label"=>"1", "date_type"=>"0", "deaccession_scope"=>"0", "digital_object_digital_object_type"=>"1", "digital_object_level"=>"1", "event_event_type"=>"1", "event_outcome"=>"1", "extent_extent_type"=>"1", "extent_portion"=>"0", "file_version_checksum_methods"=>"1", "file_version_file_format_name"=>"1", "file_version_use_statement"=>"1", "file_version_xlink_actuate_attribute"=>"0", "file_version_xlink_show_attribute"=>"0", "instance_instance_type"=>"1", "job_type"=>"0", "language_iso639_2"=>"0", "linked_agent_archival_record_relators"=>"1", "linked_agent_event_roles"=>"1", "linked_agent_role"=>"0", "linked_event_archival_record_roles"=>"0", "location_temporary"=>"1", "name_person_name_order"=>"0", "name_rule"=>"1", "name_source"=>"1", "note_bibliography_type"=>"0", "note_digital_object_type"=>"0", "note_index_type"=>"0", "note_index_item_type"=>"0", "note_multipart_type"=>"0", "note_orderedlist_enumeration"=>"0", "note_singlepart_type"=>"0", "resource_finding_aid_description_rules"=>"1", "resource_finding_aid_status"=>"1", "resource_resource_type"=>"1", "rights_statement_ip_status"=>"0", "rights_statement_rights_type"=>"0", "subject_source"=>"1", "subject_term_type"=>"0", "user_defined_enum_1"=>"1", "user_defined_enum_2"=>"1", "user_defined_enum_3"=>"1", "user_defined_enum_4"=>"1"} 


Sequel.migration do

  up do
    $stderr.puts "UPDATING OUR CONTROLLED VALUE LISTS..."
    REVIEWED_LIST.each_pair do |list, val|  
      self[:enumeration].filter(:name => list).update( :editable => val.to_i )
    end 
  end

end
