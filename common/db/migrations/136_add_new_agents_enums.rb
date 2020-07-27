require_relative 'utils'

Sequel.migration do

  up do
    $stderr.puts "Adding enumerations and values for new agents functionality"

    create_enum("maintenance_status_enum", ["new", "upgraded", "revised_corrected", "derived", "deleted", "cancelled_obsolete", "deleted_split", "deleted_replaced"])
		create_enum("publication_status_enum", ["in_process", "approved"])
		create_editable_enum("romanization_enum", ["int_std", "nat_std", "nl_assoc_std", "nl_bib_agency_std", "local_standard", "unknown_standard", "conv_rom_cat_agency", "not_applicable"])
		create_enum("government_agency_type_enum", ["ngo", "sac", "multilocal", "fed", "int_gov", "local", "multistate", "undetermined", "provincial", "unknown", "other", "natc"])
		create_enum("reference_evaluation_enum", ["tr_consistent", "tr_inconsistent", "not_applicable", "natc"])
		create_enum("name_type_enum", ["differentiated", "undifferentiated", "not_applicable", "natc"])
		create_enum("level_of_detail_enum", ["fully_established", "memorandum", "provisional", "preliminary", "not_applicable", "natc"])
		create_enum("modified_record_enum", ["not_modified", "shortened", "missing_characters", "natc"])
		create_enum("cataloging_source_enum", ["nat_bib_agency", "ccp", "other", "unknown", "natc"])
		create_enum("source_enum", ["naf", "snac", "local"], nil, true)
		create_enum("identifier_type_enum", ["loc", "lac", "local", "other_unmapped"], nil, true)
		create_enum("agency_code_type_enum", ["oclc", "local"], nil, true)
		create_enum("maintenance_event_type_enum", ["created", "cancelled", "deleted", "derived", "revised", "updated"])
		create_enum("maintenance_agent_type_enum", ["human", "machine"], "human")
		create_enum("date_type_enum", ["single", "range"])
    create_enum("date_role_enum", ["begin", "end"])
    create_enum("date_standardized_type_enum", ["standard", "not_before", "not_after"])
    create_enum("begin_date_standardized_type_enum", ["standard", "not_before", "not_after"])
    create_enum("end_date_standardized_type_enum", ["standard", "not_before", "not_after"])
  	create_editable_enum("place_role_enum", ["assoc_country", "residence", "other_assoc", "place_of_birth", "place_of_death"])
  	create_enum("agent_relationship_identity_relator", ["is_identified_with"])
  	create_enum("agent_relationship_hierarchical_relator", ["is_hierarchical_with"])
  	create_enum("agent_relationship_temporal_relator", ["is_temporal_with"])
  	create_enum("agent_relationship_family_relator", ["is_related_with"])
  	create_editable_enum("gender_enum", ["not_specified"])

    add_values_to_enum("note_multipart_type", ["general_context", "mandate", "legal_status", "structure_or_genealogy"])

  end
end
