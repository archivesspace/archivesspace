require 'factory_bot'

module FactoryBotSyntaxHelpers

  def sample(enum, exclude = [])
    values = if enum.has_key?('enum')
               enum['enum']
             elsif enum.has_key?('dynamic_enum')
               enum_source.values_for(enum['dynamic_enum'])
             else
               raise "Not sure how to sample this: #{enum.inspect}"
             end

    exclude += ['other_unmapped', 'cubits'] # cubits are smuggled in, don't allow them in sample

    values.reject {|i| exclude.include?(i) }.sample
  end


  def enum_source
    if defined? BackendEnumSource
      BackendEnumSource
    else
      JSONModel.init_args[:enum_source]
    end
  end


  def JSONModel(key)
    JSONModel::JSONModel(key)
  end


  def nil_or_whatever
    [nil, FactoryBot.generate(:alphanumstr)].sample
  end


  def few_or_none(key)
    arr = []
    rand(4).times { arr << build(key) }
    arr
  end
end

FactoryBot::SyntaxRunner.send(:include, FactoryBotSyntaxHelpers)
FactoryBot::Syntax::Default::DSL.send(:include, FactoryBotSyntaxHelpers)


FactoryBot.define do

  # General types
  sequence(:alphanumstr) { (0..4).map { rand(3)==1?rand(1000):(65 + rand(25)).chr }.join }
  sequence(:boolean_or_nil) { [nil, true, false].sample }
  sequence(:chronology_item) { {'event_date' => nil_or_whatever, 'events' => (0..rand(3)).map { FactoryBot.generate(:alphanumstr) } } }
  sequence(:container_type) {|n| 'box'}
  sequence(:downtown_address) { "#{rand(200)} #{%w(E W).sample} #{(4..9).to_a.sample}th Street" }
  sequence(:generic_description) {|n| "Description: #{n}"}
  sequence(:generic_name) {|n| "Name Number #{n}"}
  sequence(:generic_term) { |n| "Term #{n}" }
  sequence(:generic_title) { |n| "Title: #{n}"}
  sequence(:good_markup) { "<p>I'm</p><p>GOOD</p><p>#{ FactoryBot.generate(:alphanumstr)}</p>" }
  sequence(:html_title) { |n| "Title: <emph render='italic'>#{n}</emph>"}
  sequence(:integer) { rand(0..100) }
  sequence(:level) { %w(series subseries item)[rand(3)] }
  sequence(:number) { rand(100).to_s }
  sequence(:phone_number) { (3..5).to_a[rand(3)].times.map { (3..5).to_a[rand(3)].times.map { rand(9) }.join }.join(' ') }
  sequence(:repo_code) { |n| "testrepo_#{n}_#{Time.now.to_i}" }
  sequence(:sort_name) { |n| "SORT #{('a'..'z').to_a[rand(26)]} - #{n}" }
  sequence(:url) {|n| "http://www.example-#{n}-#{Time.now.to_i}.com"}
  sequence(:yyyy_mm_dd) { Time.at(rand * Time.now.to_i).to_s.sub(/\s.*/, '') }
  sequence(:username) {|n| "username_#{n}-#{Time.now.to_i}"}
  sequence(:vocab_name) {|n| "Vocabulary #{n} - #{Time.now}" }
  sequence(:vocab_refid) {|n| "vocab_ref_#{n} - #{Time.now}"}
  sequence(:wild_markup) { "<p> I AM \n WILD \n ! \n ! " + FactoryBot.generate(:alphanumstr) + "</p>" }

  # Abstract Agent Relationship
  sequence(:abstract_agent_relationship_specific_relator) { sample(JSONModel(:abstract_agent_relationship).schema['properties']['specific_relator']) }

  # Abstract Archival Object
  sequence(:relator) { sample(JSONModel(:abstract_archival_object).schema['properties']['linked_agents']['items']['properties']['relator']) }
  sequence(:resource_agent_role) { sample(JSONModel(:abstract_archival_object).schema['properties']['linked_agents']['items']['properties']['role']) }

  # Abstract Name
  sequence(:name_rule) { sample(JSONModel(:abstract_name).schema['properties']['rules']) }
  sequence(:name_source) { sample(JSONModel(:abstract_name).schema['properties']['source']) }
  sequence(:transliteration) { sample(JSONModel(:abstract_name).schema['properties']['transliteration']) }

  # Accession Parts Relationship
  sequence(:accession_parts_relator) {sample(JSONModel(:accession_parts_relationship).schema['properties']['relator'])}
  sequence(:accession_parts_relator_type) {sample(JSONModel(:accession_parts_relationship).schema['properties']['relator_type'])}

  # Accession Sibling Relationship
  sequence(:accession_sibling_relator) {sample(JSONModel(:accession_sibling_relationship).schema['properties']['relator'])}
  sequence(:accession_sibling_relator_type) {sample(JSONModel(:accession_sibling_relationship).schema['properties']['relator_type'])}

  # Agent Alternate Set
  sequence(:agent_alternate_set_file_version_xlink_actuate_attribute) { sample(JSONModel(:agent_alternate_set).schema['properties']['file_version_xlink_actuate_attribute']) }
  sequence(:agent_alternate_set_file_version_xlink_show_attribute) { sample(JSONModel(:agent_alternate_set).schema['properties']['file_version_xlink_show_attribute']) }

  # Agent Conventions Declaration
  sequence(:agent_conventions_declaration_name_rule) { sample(JSONModel(:agent_conventions_declaration).schema['properties']['name_rule']) }
  sequence(:agent_conventions_declaration_file_version_xlink_actuate_attribute) { sample(JSONModel(:agent_conventions_declaration).schema['properties']['file_version_xlink_actuate_attribute']) }
  sequence(:agent_conventions_declaration_file_version_xlink_show_attribute) { sample(JSONModel(:agent_conventions_declaration).schema['properties']['file_version_xlink_show_attribute']) }

  # Agent Maintenance History
  sequence(:agent_maintenance_history_maintenance_event_type) { sample(JSONModel(:agent_maintenance_history).schema['properties']['maintenance_event_type']) }
  sequence(:agent_maintenance_history_maintenance_agent_type) { sample(JSONModel(:agent_maintenance_history).schema['properties']['maintenance_agent_type']) }

  # Agent Other Agency Codes
  sequence(:agency_code_type) { sample(JSONModel(:agent_other_agency_codes).schema['properties']['agency_code_type']) }

  # Agent Place
  sequence(:agent_place_place_role) { sample(JSONModel(:agent_place).schema['properties']['place_role']) }

  # Agent Record Control
  sequence(:maintenance_status) { sample(JSONModel(:agent_record_control).schema['properties']['maintenance_status']) }
  sequence(:publication_status) { sample(JSONModel(:agent_record_control).schema['properties']['publication_status']) }
  sequence(:romanization) { sample(JSONModel(:agent_record_control).schema['properties']['romanization']) }
  sequence(:government_agency_type) { sample(JSONModel(:agent_record_control).schema['properties']['government_agency_type']) }
  sequence(:reference_evaluation) { sample(JSONModel(:agent_record_control).schema['properties']['reference_evaluation']) }
  sequence(:name_type) { sample(JSONModel(:agent_record_control).schema['properties']['name_type']) }
  sequence(:level_of_detail) { sample(JSONModel(:agent_record_control).schema['properties']['level_of_detail']) }
  sequence(:modified_record) { sample(JSONModel(:agent_record_control).schema['properties']['modified_record']) }
  sequence(:cataloging_source) { sample(JSONModel(:agent_record_control).schema['properties']['cataloging_source']) }

  # Agent Record Identifier
  sequence(:agent_record_identifier_source) { sample(JSONModel(:agent_record_identifier).schema['properties']['source']) }
  sequence(:agent_record_identifier_identifier_type) { sample(JSONModel(:agent_record_identifier).schema['properties']['identifier_type']) }

  # Agent Relationship
  sequence(:agent_relationship_associative_relator) {sample(JSONModel(:agent_relationship_associative).schema['properties']['relator'])}
  sequence(:agent_relationship_earlierlater_relator) {sample(JSONModel(:agent_relationship_earlierlater).schema['properties']['relator'])}
  sequence(:agent_relationship_family_relator) {sample(JSONModel(:agent_relationship_family).schema['properties']['relator'])}
  sequence(:agent_relationship_hierarchical_relator) {sample(JSONModel(:agent_relationship_hierarchical).schema['properties']['relator'])}
  sequence(:agent_relationship_identity_relator) {sample(JSONModel(:agent_relationship_identity).schema['properties']['relator'])}
  sequence(:agent_relationship_parentchild_relator) {sample(JSONModel(:agent_relationship_parentchild).schema['properties']['relator'])}
  sequence(:agent_relationship_subordinatesuperior_relator) {sample(JSONModel(:agent_relationship_subordinatesuperior).schema['properties']['relator'])}
  sequence(:agent_relationship_temporal_relator) {sample(JSONModel(:agent_relationship_temporal).schema['properties']['relator'])}

  # Agent Sources
  sequence(:agent_sources_file_version_xlink_actuate_attribute) { sample(JSONModel(:agent_sources).schema['properties']['file_version_xlink_actuate_attribute']) }
  sequence(:agent_sources_file_version_xlink_show_attribute) { sample(JSONModel(:agent_sources).schema['properties']['file_version_xlink_show_attribute']) }

  # Collection Management
  sequence(:collection_management_processing_priority) { sample(JSONModel(:collection_management).schema['properties']['processing_priority'])}
  sequence(:collection_management_processing_status) { sample(JSONModel(:collection_management).schema['properties']['processing_status'])}

  # Container Location
  sequence(:container_location_status) { sample(JSONModel(:container_location).schema['properties']['status']) }

  # Date
  sequence(:date_type) { sample(JSONModel(:date).schema['properties']['date_type']) }
  sequence(:date_label) { sample(JSONModel(:date).schema['properties']['label']) }

  # Digital Object Component
  sequence(:digital_object_component_id) { |n| "component_#{n}" }

  # Event
  sequence(:agent_role) { sample(JSONModel(:event).schema['properties']['linked_agents']['items']['properties']['role']) }
  sequence(:record_role) { sample(JSONModel(:event).schema['properties']['linked_records']['items']['properties']['role']) }
  sequence(:event_type) { sample(JSONModel(:event).schema['properties']['event_type']) }

  # Extent
  sequence(:extent_type) { sample(JSONModel(:extent).schema['properties']['extent_type']) }
  sequence(:portion) { sample(JSONModel(:extent).schema['properties']['portion']) }

  # File Version
  sequence(:use_statement) { sample(JSONModel(:file_version).schema['properties']['use_statement']) }
  sequence(:checksum_method) { sample(JSONModel(:file_version).schema['properties']['checksum_method']) }
  sequence(:xlink_actuate_attribute) { sample(JSONModel(:file_version).schema['properties']['xlink_actuate_attribute']) }
  sequence(:xlink_show_attribute) { sample(JSONModel(:file_version).schema['properties']['xlink_show_attribute']) }
  sequence(:file_format_name) { sample(JSONModel(:file_version).schema['properties']['file_format_name']) }

  # Instance
  sequence(:instance_type) { sample(JSONModel(:instance).schema['properties']['instance_type'], ['digital_object']) }

  # Language and Script
  sequence(:language) { sample(JSONModel(:language_and_script).schema['properties']['language']) }
  sequence(:script) { sample(JSONModel(:language_and_script).schema['properties']['script']) }

  # Location
  sequence(:temporary_location_type) { sample(JSONModel(:location).schema['properties']['temporary']) }

  # Note
  sequence(:note_bibliography_type) { sample(JSONModel(:note_bibliography).schema['properties']['type'])}
  sequence(:digital_object_note_type) { sample(JSONModel(:note_digital_object).schema['properties']['type'])}
  sequence(:note_index_item_type) { sample(JSONModel(:note_index_item).schema['properties']['type'])}
  sequence(:note_index_type) { sample(JSONModel(:note_index).schema['properties']['type'])}
  sequence(:langmaterial_note_type) { sample(JSONModel(:note_langmaterial).schema['properties']['type'])}
  sequence(:multipart_note_type) { sample(JSONModel(:note_multipart).schema['properties']['type'])}
  sequence(:orderedlist_enumeration) { sample(JSONModel(:note_orderedlist).schema['properties']['enumeration']) }
  sequence(:rights_statement_act_note_type) { sample(JSONModel(:note_rights_statement_act).schema['properties']['type'])}
  sequence(:rights_statement_note_type) { sample(JSONModel(:note_rights_statement).schema['properties']['type'])}
  sequence(:singlepart_note_type) { sample(JSONModel(:note_singlepart).schema['properties']['type'])}

  # Resource
  sequence(:archival_record_level) { sample(JSONModel(:resource).schema['properties']['level'], ['otherlevel']) }
  sequence(:finding_aid_description_rules) { sample(JSONModel(:resource).schema['properties']['finding_aid_description_rules']) }
  sequence(:finding_aid_language) { sample(JSONModel(:resource).schema['properties']['finding_aid_language']) }
  sequence(:finding_aid_script) { sample(JSONModel(:resource).schema['properties']['finding_aid_script']) }

  # Rights Restriction
  sequence(:restriction_type) {sample(JSONModel(:rights_restriction).schema['properties']['local_access_restriction_type']['items'])}

  # Rights Statement Act
  sequence(:act_type) { sample(JSONModel(:rights_statement_act).schema['properties']['act_type']) }
  sequence(:act_restriction) { sample(JSONModel(:rights_statement_act).schema['properties']['restriction']) }

  # Rights Statement External Document
  sequence(:external_document_identifier_type) { sample(JSONModel(:rights_statement_external_document).schema['properties']['identifier_type']) }

  # Rights Statement
  sequence(:rights_type) { sample(JSONModel(:rights_statement).schema['properties']['rights_type']) }
  sequence(:status) { sample(JSONModel(:rights_statement).schema['properties']['status']) }
  sequence(:jurisdiction) { sample(JSONModel(:rights_statement).schema['properties']['jurisdiction']) }
  sequence(:other_rights_basis) { sample(JSONModel(:rights_statement).schema['properties']['other_rights_basis']) }

  # Subject
  sequence(:subject_source) { sample(JSONModel(:subject).schema['properties']['source']) }

  # Term
  sequence(:term_type) { sample(JSONModel(:term).schema['properties']['term_type']) }

  # User Defined
  sequence(:user_defined_enum_1) { sample(JSONModel(:user_defined).schema['properties']['enum_1']) }
  sequence(:user_defined_enum_2) { sample(JSONModel(:user_defined).schema['properties']['enum_2']) }
  sequence(:user_defined_enum_3) { sample(JSONModel(:user_defined).schema['properties']['enum_3']) }
  sequence(:user_defined_enum_4) { sample(JSONModel(:user_defined).schema['properties']['enum_4']) }

  factory :json_accession_parts_relationship, class: JSONModel(:accession_parts_relationship) do
    relator { generate(:accession_parts_relator) }
    relator_type { generate(:accession_parts_relator_type) }
    ref { create(:json_accession).uri }
  end

  factory :json_accession_sibling_relationship, class: JSONModel(:accession_sibling_relationship) do
    relator { generate(:accession_sibling_relator) }
    relator_type { generate(:accession_sibling_relator_type) }
    ref { create(:json_accession).uri }
  end

  factory :json_accession, class: JSONModel(:accession) do
    id_0 { generate(:alphanumstr) }
    id_1 { generate(:alphanumstr) }
    id_2 { generate(:alphanumstr) }
    id_3 { generate(:alphanumstr) }
    title { "Accession " + generate(:generic_title) }
    content_description { generate(:generic_description) }
    condition_description { generate(:generic_description) }
    accession_date { generate(:yyyy_mm_dd) }
    extents { [build(:json_extent)] }
  end

  factory :json_active_edits, class: JSONModel(:active_edits) do
    active_edits { [{
      'user' => generate(:username),
      'uri' => generate(:alphanumstr),
      'time' => generate(:alphanumstr)
      }] }
  end

  factory :json_advanced_query, class: JSONModel(:advanced_query) do
    query { build(:json_boolean_query) }
  end

  factory :json_agent_alternate_set, class: JSONModel(:agent_alternate_set) do
    set_component { generate(:alphanumstr) }
    descriptive_note { generate(:alphanumstr) }
    file_uri { generate(:alphanumstr) }
    file_version_xlink_actuate_attribute { generate(:agent_alternate_set_file_version_xlink_actuate_attribute) }
    file_version_xlink_show_attribute { generate(:agent_alternate_set_file_version_xlink_show_attribute) }
  end

  factory :json_agent_contact, class: JSONModel(:agent_contact) do
    name { generate(:generic_name) }
    telephones { [build(:json_telephone)] }
    address_1 { nil_or_whatever }
    address_2 { nil_or_whatever }
    address_3 { nil_or_whatever }
    city { nil_or_whatever }
    region { nil_or_whatever }
    country { nil_or_whatever }
    post_code { nil_or_whatever }
    fax { nil_or_whatever }
    email { nil_or_whatever }
    email_signature { nil_or_whatever }
    notes { [build(:json_note_contact_note)] }
    is_representative { false }
  end

  factory :json_agent_conventions_declaration, class: JSONModel(:agent_conventions_declaration) do
    name_rule { generate(:agent_conventions_declaration_name_rule) }
    citation { nil_or_whatever }
    descriptive_note { nil_or_whatever }
    file_uri { nil_or_whatever }
    file_version_xlink_actuate_attribute { generate(:agent_conventions_declaration_file_version_xlink_actuate_attribute) }
    file_version_xlink_show_attribute { generate(:agent_conventions_declaration_file_version_xlink_show_attribute) }
    xlink_title_attribute { nil_or_whatever }
    xlink_role_attribute { nil_or_whatever }
    xlink_arcrole_attribute { nil_or_whatever }
    last_verified_date { generate(:yyyy_mm_dd) }
  end

  factory :json_agent_corporate_entity, class: JSONModel(:agent_corporate_entity) do
    agent_type { 'agent_corporate_entity' }
    names { [build(:json_name_corporate_entity)] }
    agent_contacts { [build(:json_agent_contact)] }
    dates_of_existence { [build(:json_structured_date_label)] }
  end

  factory :json_agent_family, class: JSONModel(:agent_family) do
    agent_type { 'agent_family' }
    names { [build(:json_name_family)] }
    dates_of_existence { [build(:json_structured_date_label)] }
  end

  factory :json_agent_function, class: JSONModel(:agent_function) do
    publish { generate(:boolean_or_nil) }
    notes { [build(:json_note_text)] }
    dates { [build(:json_structured_date_label)] }
    subjects { ['ref' => create(:json_subject).uri] }
    places { ['ref' => create(:json_subject).uri] }
  end

  # NOTE: using this factory will fail unless values are added manually to the gender enum list. See agent_spec_helper.rb#add_gender_values
  factory :json_agent_gender, class: JSONModel(:agent_gender) do
    dates { [build(:json_structured_date_label)] }
    gender { 'not_specified' }
    notes { [build(:json_note_text)] }
  end

  factory :json_agent_identifier, class: JSONModel(:agent_identifier) do
    entity_identifier { generate(:alphanumstr) }
    identifier_type { "loc"}
  end

  factory :json_agent_maintenance_history, class: JSONModel(:agent_maintenance_history) do
    maintenance_event_type { generate(:agent_maintenance_history_maintenance_event_type) }
    maintenance_agent_type { generate(:agent_maintenance_history_maintenance_agent_type) }
    event_date { generate(:yyyy_mm_dd) }
    agent { generate(:alphanumstr) }
    descriptive_note { generate(:alphanumstr) }
  end

  factory :json_agent_occupation, class: JSONModel(:agent_occupation) do
    publish { true }
    notes { [build(:json_note_text)] }
    dates { [build(:json_structured_date_label)] }
    subjects { [{'ref' => create(:json_subject).uri}] }
    places { [{'ref' => create(:json_subject).uri}] }
  end

  factory :json_agent_other_agency_codes, class: JSONModel(:agent_other_agency_codes) do
    agency_code_type { generate(:agency_code_type) }
    maintenance_agency { generate(:alphanumstr) }
  end

  factory :json_agent_person, class: JSONModel(:agent_person) do
    agent_type { 'agent_person' }
    names { [build(:json_name_person)] }
    dates_of_existence { [build(:json_structured_date_label)] }
  end

  factory :json_agent_place, class: JSONModel(:agent_place) do
    publish { generate(:boolean_or_nil) }
    place_role { generate(:agent_place_place_role) }
    dates { [build(:json_structured_date_label)] }
    notes { [build(:json_note_text)] }
    subjects { [{'ref' => create(:json_subject).uri}] }
  end

  factory :json_agent_record_control, class: JSONModel(:agent_record_control) do
    maintenance_status { generate(:maintenance_status) }
    publication_status { [nil, generate(:publication_status)].sample }
    romanization { [nil, generate(:romanization)].sample }
    government_agency_type { [nil, generate(:government_agency_type)].sample }
    reference_evaluation { [nil, generate(:reference_evaluation)].sample }
    name_type { [nil, generate(:name_type)].sample }
    level_of_detail { [nil, generate(:level_of_detail)].sample }
    modified_record { [nil, generate(:modified_record)].sample }
    cataloging_source { [nil, generate(:cataloging_source)].sample }
    language { [nil, generate(:language)].sample }
    script { [nil, generate(:script)].sample }
    language_note { nil_or_whatever }
    maintenance_agency { nil_or_whatever }
    agency_name { nil_or_whatever }
    maintenance_agency_note { nil_or_whatever }
  end

  factory :json_agent_record_identifier, class: JSONModel(:agent_record_identifier) do
    primary_identifier { true }
    record_identifier { generate(:alphanumstr) }
    source { generate(:agent_record_identifier_source) }
    identifier_type { generate(:agent_record_identifier_identifier_type) }
  end

  factory :json_agent_relationship_associative, class: JSONModel(:agent_relationship_associative) do
    relator { generate(:agent_relationship_associative_relator) }
    ref { create(:json_agent_family).uri }
  end

  factory :json_agent_relationship_earlierlater, class: JSONModel(:agent_relationship_earlierlater) do
    relator { generate(:agent_relationship_earlierlater_relator) }
    ref { create(:json_agent_family).uri }
  end

  factory :json_agent_relationship_family, class: JSONModel(:agent_relationship_family) do
    relator { generate(:agent_relationship_family_relator) }
    ref { create(:json_agent_corporate_entity).uri }
  end

  factory :json_agent_relationship_hierarchical, class: JSONModel(:agent_relationship_hierarchical) do
    relator { generate(:agent_relationship_hierarchical_relator) }
    ref { create(:json_agent_person).uri }
  end

  factory :json_agent_relationship_identity, class: JSONModel(:agent_relationship_identity) do
    relator { generate(:agent_relationship_identity_relator) }
    ref { create(:json_agent_person).uri }
  end

  factory :json_agent_relationship_parentchild, class: JSONModel(:agent_relationship_parentchild) do
    relator { generate(:agent_relationship_parentchild_relator) }
    ref { create(:json_agent_person).uri }
  end

  factory :json_agent_relationship_subordinatesuperior, class: JSONModel(:agent_relationship_subordinatesuperior) do
    relator { generate(:agent_relationship_subordinatesuperior_relator) }
    ref { create(:json_agent_corporate_entity).uri }
  end

  factory :json_agent_relationship_temporal, class: JSONModel(:agent_relationship_temporal) do
    relator { generate(:agent_relationship_temporal_relator) }
    ref { create(:json_agent_corporate_entity).uri }
  end

  factory :json_agent_resource, class: JSONModel(:agent_resource) do
    publish { true }
    linked_agent_role { "creator" }
    linked_resource { generate(:alphanumstr) }
    linked_resource_description { generate(:alphanumstr) }
    file_uri { generate(:alphanumstr) }
    file_version_xlink_actuate_attribute { "other"}
    file_version_xlink_show_attribute { "other" }
    xlink_title_attribute { generate(:alphanumstr) }
    xlink_role_attribute { generate(:alphanumstr) }
    xlink_arcrole_attribute { generate(:alphanumstr) }
    last_verified_date { generate(:yyyy_mm_dd) }
    dates { [build(:json_structured_date_label)] }
    places { [{'ref' => create(:json_subject).uri}] }
  end

  factory :json_agent_software, class: JSONModel(:agent_software) do
    agent_type { 'agent_software' }
    names { [build(:json_name_software)] }
    dates_of_existence { [build(:json_structured_date_label)] }
  end

  factory :json_agent_sources, class: JSONModel(:agent_sources) do
    file_version_xlink_actuate_attribute { generate(:agent_sources_file_version_xlink_actuate_attribute) }
    file_version_xlink_show_attribute { generate(:agent_sources_file_version_xlink_show_attribute) }
    descriptive_note { generate(:alphanumstr) }
    source_entry { generate(:alphanumstr) }
    file_uri { generate(:alphanumstr) }
    xlink_title_attribute { generate(:alphanumstr) }
    xlink_role_attribute { generate(:alphanumstr) }
    xlink_arcrole_attribute { generate(:alphanumstr) }
    last_verified_date { generate(:yyyy_mm_dd) }
  end

  factory :json_agent_topic, class: JSONModel(:agent_topic) do
    publish { generate(:boolean_or_nil) }
    dates { [build(:json_structured_date_label)] }
    notes { [build(:json_note_text)] }
    subjects { [{
      'ref' => create(:json_subject).uri
      }] }
    places { [{
      'ref' => create(:json_subject).uri
      }] }
  end

  factory :json_archival_object, class: JSONModel(:archival_object) do
    ref_id { generate(:alphanumstr) }
    level { generate(:level) }
    title { "Archival Object #{generate(:generic_title)}" }
    extents { few_or_none(:json_extent) }
    dates { few_or_none(:json_date) }
    resource { {'ref' => create(:json_resource).uri} }
  end

  factory :json_archival_record_children, class: JSONModel(:archival_record_children) do
    children { [ create(:json_archival_object), create(:json_archival_object) ] }
  end

  factory :json_ark_name, class: JSONModel(:ark_name) do
    current { nil_or_whatever }
    current_is_external { generate(:boolean_or_nil) }
    previous { [generate(:alphanumstr)] }
  end

  factory :json_assessment_attribute_definitions, class: JSONModel(:assessment_attribute_definitions) do
    definitions { [{
      'id' => generate(:integer),
      'label' => generate(:alphanumstr),
      'type' => ['rating', 'format', 'conservation_issue'].sample,
      'global' => false,
      'readonly' => false,
      'position' => generate(:integer)
      }] }
  end

  factory :json_assessment_attribute, class: JSONModel(:assessment_attribute) do
    definition_id { generate(:integer) }
    value { nil_or_whatever }
    note { nil_or_whatever }
    readonly { false }
  end

  factory :json_assessment, class: JSONModel(:assessment) do
    records { [ {'ref' => create(:json_resource).uri} ] }
    accession_report { generate(:boolean_or_nil) }
    appraisal { generate(:boolean_or_nil) }
    container_list { generate(:boolean_or_nil) }
    catalog_record { generate(:boolean_or_nil) }
    control_file { generate(:boolean_or_nil) }
    deed_of_gift { generate(:boolean_or_nil) }
    finding_aid_ead { generate(:boolean_or_nil) }
    finding_aid_online { generate(:boolean_or_nil) }
    finding_aid_paper { generate(:boolean_or_nil) }
    finding_aid_word { generate(:boolean_or_nil) }
    finding_aid_spreadsheet { generate(:boolean_or_nil) }
    related_eac_records { generate(:boolean_or_nil) }
    existing_description_notes { nil_or_whatever }
    surveyed_by { [ {'ref' => create(:json_agent_person).uri} ] }
    survey_begin { generate(:yyyy_mm_dd) }
    surveyed_duration { nil_or_whatever }
    surveyed_extent { nil_or_whatever }
    review_required { generate(:boolean_or_nil) }
    reviewer { [ {'ref' => create(:json_agent_person).uri} ] }
    review_note { nil_or_whatever }
    inactive { generate(:boolean_or_nil) }
    purpose { nil_or_whatever }
    scope { nil_or_whatever }
    sensitive_material { generate(:boolean_or_nil) }
    formats { [{'ref' => build(:json_assessment_attribute)}] }
    conservation_issues { [{'ref' => build(:json_assessment_attribute)}] }
    ratings { [{'ref' => build(:json_assessment_attribute)}] }
    general_assessment_note { nil_or_whatever }
    special_format_note { nil_or_whatever }
    exhibition_value_note { nil_or_whatever }
    monetary_value { generate(:number) }
    monetary_value_note { nil_or_whatever }
    conservation_note { nil_or_whatever }
  end

  factory :json_boolean_field_query, class: JSONModel(:boolean_field_query) do
    field { generate(:alphanumstr) }
    value { [true, false].sample }
    negated { false }
  end

  factory :json_boolean_query, class: JSONModel(:boolean_query) do
    op { 'AND' }
    subqueries { [build(:json_date_field_query)] }
  end

  factory :json_bulk_import_job, class: JSONModel(:bulk_import_job) do
    resource_id { generate(:alphanumstr) }
    filename { generate(:alphanumstr) }
    load_type { generate(:alphanumstr) }
    content_type { generate(:alphanumstr) }
    format { generate(:alphanumstr) }
    only_validate { generate(:alphanumstr) }
  end

  factory :json_bulk_archival_object_updater_job, class: JSONModel(:bulk_archival_object_updater_job) do
    create_missing_top_containers { false }
  end

  factory :json_classification_term, class: JSONModel(:classification_term) do
    identifier { generate(:alphanumstr) }
    title { "Classification #{generate(:generic_title)}" }
    description { generate(:generic_description) }
    classification { {'ref' => create(:json_classification).uri} }
  end

  factory :json_classification_tree, class: JSONModel(:classification_tree) do
    id { generate(:integer) }
    record_uri { generate(:alphanumstr) }
    identifier { generate(:alphanumstr) }
    children { [ ] }
  end

  factory :json_classification, class: JSONModel(:classification) do
    identifier { generate(:alphanumstr) }
    title { "Classification #{generate(:generic_title)}" }
    description { generate(:generic_description) }
  end

  factory :json_collection_management, class: JSONModel(:collection_management) do
    external_ids { [build(:json_external_id)] }
    processing_hours_per_foot_estimate { generate(:number) }
    processing_total_extent { generate(:number) }
    processing_total_extent_type { generate(:extent_type) }
    processing_hours_total { generate(:number) }
    processing_plan { nil_or_whatever }
    processing_priority { generate(:collection_management_processing_priority) }
    processing_funding_source { nil_or_whatever }
    processors { nil_or_whatever }
    rights_determined { generate(:boolean_or_nil) }
    processing_status { generate(:collection_management_processing_status) }
  end

  factory :json_container_conversion_job, class: JSONModel(:container_conversion_job) do
    format { generate(:alphanumstr) }
  end

  factory :json_container_labels_job, class: JSONModel(:container_labels_job) do
    source { create(:json_resource).uri }
  end

  factory :json_container_location, class: JSONModel(:container_location) do
    status { generate(:container_location_status) }
    start_date { generate(:yyyy_mm_dd) }
    end_date { generate(:yyyy_mm_dd) }
    note { generate(:alphanumstr) }
    ref { create(:json_location).uri }
  end

  factory :json_container_profile, class: JSONModel(:container_profile) do
    name { generate(:alphanumstr) }
    url { generate(:alphanumstr) }
    dimension_units { sample(JSONModel(:container_profile).schema['properties']['dimension_units']) }
    extent_dimension { sample(JSONModel(:container_profile).schema['properties']['extent_dimension']) }
    depth { rand(100).to_s }
    height { rand(100).to_s }
    width { rand(100).to_s }
  end

  factory :json_custom_report_template, class: JSONModel(:custom_report_template) do
    name { "template" }
    description { "good template" }
    data { {fields: {foo: {include: 1}} }.to_json }
    limit { 10 }
  end

  factory :json_date_field_query, class: JSONModel(:date_field_query) do
    comparator { [nil, 'greater_than', 'lesser_than', 'equal', 'empty'].sample }
    field { generate(:alphanumstr) }
    value { generate(:yyyy_mm_dd) }
    negated { false }
  end

  factory :json_date, class: JSONModel(:date) do
    date_type { generate(:date_type) }
    label { 'creation' }
    self.begin { generate(:yyyy_mm_dd) }
    self.end { self.begin }
    certainty { 'inferred' }
    era { 'ce' }
    calendar { 'gregorian' }
    expression { generate(:alphanumstr) }
  end

  factory :json_deaccession, class: JSONModel(:deaccession) do
    scope { "whole" }
    description { generate(:generic_description) }
    date { build(:json_date) }
  end

  factory :json_default_values, class: JSONModel(:default_values) do
    record_type { ['archival_object', 'digital_object_component', 'resource', 'accession', 'subject', 'digital_object', 'agent_person', 'agent_family', 'agent_software', 'agent_corporate_entity', 'event', 'location', 'classification', 'classification_term'].sample }
    defaults {}
  end

  factory :json_defaults, class: JSONModel(:defaults) do
    show_suppressed { false }
    publish { false }
  end

  factory :json_digital_object_component, class: JSONModel(:digital_object_component) do
    component_id { generate(:digital_object_component_id) }
    title { "Digital Object Component #{generate(:generic_title)}" }
    digital_object { {'ref' => create(:json_digital_object).uri} }
    position { generate(:integer) }
    has_unpublished_ancestor { false }
  end

  factory :json_digital_object_tree, class: JSONModel(:digital_object_tree) do
    id { generate(:integer) }
    record_uri { generate(:alphanumstr) }
    level { nil_or_whatever }
    file_versions { [build(:json_file_version)] }
    digital_object_type { generate(:alphanumstr) }
    children { [ ] }
  end

  factory :json_digital_object, class: JSONModel(:digital_object) do
    title { "Digital Object #{generate(:generic_title)}" }
    lang_materials { [build(:json_lang_material)] }
    digital_object_id { generate(:alphanumstr) }
    extents { [build(:json_extent)] }
    file_versions { few_or_none(:json_file_version) }
    dates { few_or_none(:json_date) }
  end

  factory :json_digital_record_children, class: JSONModel(:digital_record_children) do
    children { few_or_none(:json_digital_object_component) }
  end

  factory :json_enumeration_migration, class: JSONModel(:enumeration_migration) do
    enum_uri { create(:json_enumeration).uri }
    from { generate(:alphanumstr) }
    to { generate(:alphanumstr) }
  end

  factory :json_enumeration_value, class: JSONModel(:enumeration_value) do
    value { generate(:alphanumstr) }
    position { generate(:integer) }
    suppressed { generate(:boolean_or_nil) }
  end

  factory :json_enumeration, class: JSONModel(:enumeration) do
    name { generate(:alphanumstr) }
    relationships { [generate(:alphanumstr)] }
    enumeration_values { [build(:json_enumeration_value)] }
    values { [generate(:alphanumstr)] }
  end

  factory :json_event, class: JSONModel(:event) do
    date { build(:json_date) }
    event_type { generate(:event_type) }
    linked_agents { [{'ref' => create(:json_agent_person).uri, 'role' => generate(:agent_role)}] }
    linked_records { [{'ref' => create(:json_accession).uri, 'role' => generate(:record_role)}] }
  end

  factory :json_extent, class: JSONModel(:extent) do
    portion { generate(:portion) }
    number { generate(:number) }
    extent_type { generate(:extent_type) }
    dimensions { generate(:alphanumstr) }
    physical_details { generate(:alphanumstr) }
  end

  factory :json_external_document, class: JSONModel(:external_document) do
    title { "External Document #{generate(:generic_title)}" }
    location { generate(:url) }
  end

  factory :json_external_id, class: JSONModel(:external_id) do
    external_id { generate(:alphanumstr) }
    source { generate(:alphanumstr) }
  end

  factory :json_field_query, class: JSONModel(:field_query) do
    negated { generate(:boolean_or_nil) }
    field { generate(:alphanumstr) }
    value { generate(:alphanumstr) }
    literal { generate(:boolean_or_nil) }
    comparator { [nil, 'contains', 'empty'].sample }
  end

  factory :json_file_version, class: JSONModel(:file_version) do
    file_uri { generate(:alphanumstr) }
    use_statement { generate(:use_statement) }
    xlink_actuate_attribute { generate(:xlink_actuate_attribute) }
    xlink_show_attribute { generate(:xlink_show_attribute) }
    file_format_name { generate(:file_format_name) }
    file_format_version { generate(:alphanumstr) }
    file_size_bytes { generate(:number).to_i }
    checksum { generate(:alphanumstr) }
    checksum_method { generate(:checksum_method) }
    publish { true }
  end

  factory :json_find_and_replace_job, class: JSONModel(:find_and_replace_job) do
    find { "/foo/" }
    replace { "bar" }
    record_type { "extent" }
    property { "container_summary" }
    base_record_uri { "repositories/2/resources/1" }
  end

  factory :json_generate_arks_job, class: JSONModel(:generate_arks_job) do
    {}
  end

  factory :json_generate_slugs_job, class: JSONModel(:generate_slugs_job) do
    {}
  end

  factory :json_ns2_remover_job, class: JSONModel(:ns2_remover_job) do
    dry_run { false }
  end

  factory :json_group, class: JSONModel(:group) do
    group_code { generate(:alphanumstr) }
    description { generate(:generic_description) }
  end

  factory :json_import_job, class: JSONModel(:import_job) do
    import_type { ['marcxml', 'ead_xml', 'eac_xml'].sample }
    filenames { (0..3).map { generate(:alphanumstr) } }
  end

  factory :json_instance, class: JSONModel(:instance) do
    instance_type { generate(:instance_type) }
    sub_container { build(:json_sub_container) }
  end

  factory :json_job, class: JSONModel(:job) do
    job { build(:json_import_job) }
  end

  factory :json_lang_material, class: JSONModel(:lang_material) do
    language_and_script { build(:json_language_and_script) }
  end

  factory :json_language_and_script, class: JSONModel(:language_and_script) do
    language { generate(:language) }
    script { generate(:script) }
  end

  factory :json_location_batch_update, class: JSONModel(:location_batch_update) do
    building { generate(:alphanumstr) }
    record_uris { [create(:json_location).uri, create(:json_location).uri] }
  end

  factory :json_location_batch, class: JSONModel(:location_batch) do
    building { generate(:alphanumstr) }
    locations { [create(:json_location).uri, create(:json_location).uri] }
    coordinate_1_range { {'label' => 'Range', 'start' => '1', 'end' => '10'} }
    coordinate_2_range { {'label' => 'Section', 'start' => 'A', 'end' => 'M'} }
    coordinate_3_range { {'label' => 'Shelf', 'start' => '1', 'end' => '7'} }
  end

  factory :json_location_function, class: JSONModel(:location_function) do
    location_function_type { sample(JSONModel(:location_function).schema['properties']['location_function_type']) }
  end

  factory :json_location_profile, class: JSONModel(:location_profile) do
    name { generate(:alphanumstr) }
    dimension_units { sample(JSONModel(:location_profile).schema['properties']['dimension_units']) }
    depth { rand(100).to_s }
    height { rand(100).to_s }
    width { rand(100).to_s }
  end

  factory :json_location, class: JSONModel(:location) do
    building { generate(:downtown_address) }
    floor { "#{rand(13)}" }
    room { "#{rand(20)}" }
    area { %w(Back Front).sample }
    barcode { generate(:barcode) }
    temporary { generate(:temporary_location_type) }
  end

  factory :json_merge_request_detail, class: JSONModel(:merge_request_detail) do
    merge_destination { {'ref' => create(:json_agent_person).uri} }
    merge_candidates { [ {'ref' => create(:json_agent_person).uri}, {'ref' => create(:json_agent_person).uri} ] }
    selections {}
  end

  factory :json_merge_request, class: JSONModel(:merge_request) do
    merge_destination { {'ref' => create(:json_subject).uri} }
    merge_candidates { [ {'ref' => create(:json_subject).uri}, {'ref' => create(:json_subject).uri} ] }
  end

  factory :json_metadata_rights_declaration, class: JSONModel(:metadata_rights_declaration) do
    license { "public_domain" }
    descriptive_note { "too fast" }
    file_uri { "http://example.com" }
    file_version_xlink_actuate_attribute { "other"}
    file_version_xlink_show_attribute { "other" }
    xlink_title_attribute { generate(:alphanumstr) }
    xlink_role_attribute { generate(:alphanumstr) }
    xlink_arcrole_attribute { generate(:alphanumstr) }
    last_verified_date { "2021-05-19" }
  end

  factory :json_name_corporate_entity, class: JSONModel(:name_corporate_entity) do
    rules { generate(:name_rule) }
    primary_name { generate(:generic_name) }
    subordinate_name_1 { generate(:alphanumstr) }
    subordinate_name_2 { generate(:alphanumstr) }
    number { generate(:alphanumstr) }
    sort_name { generate(:sort_name) }
    sort_name_auto_generate { true }
    qualifier { generate(:alphanumstr) }
    use_dates { [build(:json_structured_date_label)] }
    dates { generate(:alphanumstr) }
    authority_id { generate(:url) }
    source { generate(:name_source) }
  end

  factory :json_name_family, class: JSONModel(:name_family) do
    rules { generate(:name_rule) }
    family_name { generate(:generic_name) }
    sort_name { generate(:sort_name) }
    sort_name_auto_generate { true }
    use_dates { [build(:json_structured_date_label)] }
    dates { generate(:alphanumstr) }
    qualifier { generate(:alphanumstr) }
    prefix { generate(:alphanumstr) }
    authority_id { generate(:url) }
    source { generate(:name_source) }
  end

  factory :json_name_form, class: JSONModel(:name_form) do
    kind { generate(:alphanumstr) }
    sort_name { generate(:alphanumstr) }
  end

  factory :json_name_person, class: JSONModel(:name_person) do
    rules { generate(:name_rule) }
    source { generate(:name_source) }
    primary_name { generate(:generic_name) }
    sort_name { generate(:sort_name) }
    name_order { %w(direct inverted).sample }
    number { generate(:alphanumstr) }
    sort_name_auto_generate { true }
    use_dates { [build(:json_structured_date_label)] }
    dates { generate(:alphanumstr) }
    qualifier { generate(:alphanumstr) }
    fuller_form { generate(:alphanumstr) }
    prefix { generate(:alphanumstr) }
    title { generate(:alphanumstr) }
    suffix { generate(:alphanumstr) }
    rest_of_name { generate(:alphanumstr) }
    authority_id { generate(:url) }
  end

  factory :json_name_software, class: JSONModel(:name_software) do
    rules { generate(:name_rule) }
    source { generate(:name_source) }
    software_name { generate(:generic_name) }
    sort_name { generate(:sort_name) }
    sort_name_auto_generate { true }
    qualifier { generate(:alphanumstr) }
    use_dates { [build(:json_structured_date_label)] }
    dates { generate(:alphanumstr) }
    authority_id { generate(:url) }
  end

  factory :json_note_abstract, class: JSONModel(:note_abstract) do
    content { (0..rand(3)).map { generate(:good_markup) } }
  end

  factory :json_note_agent_rights_statement, class: JSONModel(:note_agent_rights_statement) do
    content { [ generate(:alphanumstr), generate(:alphanumstr) ] }
  end

  factory :json_note_bibliography, class: JSONModel(:note_bibliography) do
    label { [ generate(:alphanumstr), nil].sample }
    content { [generate(:wild_markup)] }
    items { [generate(:alphanumstr)] }
    type { [ generate(:note_bibliography_type), nil].sample }
  end

  factory :json_note_bioghist, class: JSONModel(:note_bioghist) do
    label { generate(:alphanumstr) }
    subnotes { [ build(:json_note_text), build(:json_note_text) ] }
  end

  factory :json_note_chronology, class: JSONModel(:note_chronology) do
    title { nil_or_whatever }
    items { (0..rand(3)).map { generate(:chronology_item) } }
  end

  factory :json_note_citation, class: JSONModel(:note_citation) do
    content { (0..rand(3)).map { generate(:good_markup) } }
    xlink { Hash[%w(actuate arcrole href role show title type).map {|i| [i, i]}] }
  end

  factory :json_note_contact_note, class: JSONModel(:note_contact_note) do
    date_of_contact { generate(:alphanumstr) }
    contact_notes { generate(:alphanumstr) }
  end

  factory :json_note_definedlist, class: JSONModel(:note_definedlist) do
    title { nil_or_whatever }
    items { (0..rand(3)).map { {:label => generate(:alphanumstr), :value => generate(:alphanumstr) } } }
  end

  factory :json_note_digital_object, class: JSONModel(:note_digital_object) do
    type { generate(:digital_object_note_type)}
    content { [ generate(:alphanumstr), generate(:alphanumstr) ] }
  end

  factory :json_note_general_context, class: JSONModel(:note_general_context) do
    label { generate(:alphanumstr) }
    subnotes { [ build(:json_note_text), build(:json_note_text) ] }
  end

  factory :json_note_index_item, class: JSONModel(:note_index_item) do
    value { generate(:alphanumstr) }
    type { generate(:note_index_item_type) }
  end

  factory :json_note_index, class: JSONModel(:note_index) do
    type { generate(:note_index_type)}
    content { [ generate(:alphanumstr), generate(:alphanumstr) ] }
    items { [ build(:json_note_index_item), build(:json_note_index_item) ] }
  end

  factory :json_note_langmaterial, class: JSONModel(:note_langmaterial) do
    type { generate(:langmaterial_note_type)}
    content { [ generate(:alphanumstr), generate(:alphanumstr) ] }
  end

  factory :json_note_legal_status, class: JSONModel(:note_legal_status) do
    label { generate(:alphanumstr) }
    subnotes { [ build(:json_note_text) ] }
  end

  factory :json_note_mandate, class: JSONModel(:note_mandate) do
    label { generate(:alphanumstr) }
    subnotes { [ build(:json_note_text) ] }
  end

  factory :json_note_multipart, class: JSONModel(:note_multipart) do
    type { 'scopecontent' }
    subnotes { [ build(:json_note_text, :publish => true) ] }
    publish { true }
  end

  factory :json_note_orderedlist, class: JSONModel(:note_orderedlist) do
    title { nil_or_whatever }
    enumeration { generate(:orderedlist_enumeration) }
    items { (0..rand(3)).map { generate(:alphanumstr) } }
  end

  factory :json_note_outline_level, class: JSONModel(:note_outline_level) do
    items { [ generate(:alphanumstr) ] }
  end

  factory :json_note_outline, class: JSONModel(:note_outline) do
    levels { [ build(:json_note_outline_level) ] }
  end

  factory :json_note_rights_statement_act, class: JSONModel(:note_rights_statement_act) do
    type { generate(:rights_statement_act_note_type)}
    content { [ generate(:alphanumstr), generate(:alphanumstr) ] }
  end

  factory :json_note_rights_statement, class: JSONModel(:note_rights_statement) do
    type { generate(:rights_statement_note_type)}
    content { [ generate(:alphanumstr), generate(:alphanumstr) ] }
  end

  factory :json_note_singlepart, class: JSONModel(:note_singlepart) do
    type { generate(:singlepart_note_type)}
    content { [ generate(:alphanumstr), generate(:alphanumstr) ] }
  end

  factory :json_note_structure_or_genealogy, class: JSONModel(:note_structure_or_genealogy) do
    label { generate(:alphanumstr) }
    subnotes { [ build(:json_note_text) ] }
  end

  factory :json_note_text, class: JSONModel(:note_text) do
    content { generate(:alphanumstr) }
  end

  factory :json_oai_config, class: JSONModel(:oai_config) do
    oai_record_prefix { 'archivesspace:oai' }
    oai_admin_email { 'oairecord@example.org' }
    oai_repository_name { 'ArchivesSpace OAI Repo' }
  end

  factory :json_parallel_name_corporate_entity, class: JSONModel(:parallel_name_corporate_entity) do
    primary_name { generate(:generic_name) }
    subordinate_name_1  { generate(:alphanumstr) }
    subordinate_name_2  { generate(:alphanumstr) }
    number { generate(:alphanumstr) }
    location { generate(:alphanumstr) }
    conference_meeting { generate(:boolean_or_nil) }
    jurisdiction { generate(:boolean_or_nil) }
  end

  factory :json_parallel_name_family, class: JSONModel(:parallel_name_family) do
    family_name { generate(:generic_name) }
    prefix { nil_or_whatever }
    location { nil_or_whatever }
    family_type { nil_or_whatever }
  end

  factory :json_parallel_name_person, class: JSONModel(:parallel_name_person) do
    primary_name { generate(:generic_name) }
    name_order { %w(direct inverted).sample }
    number { generate(:alphanumstr) }
    qualifier { generate(:alphanumstr) }
    use_dates { [build(:json_structured_date_label)] }
    dates { generate(:alphanumstr) }
    fuller_form { generate(:alphanumstr) }
    prefix { nil_or_whatever }
    title { nil_or_whatever }
    suffix { nil_or_whatever }
    rest_of_name { nil_or_whatever }
  end

  factory :json_parallel_name_software, class: JSONModel(:parallel_name_software) do
    software_name { generate(:generic_name) }
    version { nil_or_whatever }
    manufacturer { nil_or_whatever }
  end

  factory :json_permission, class: JSONModel(:permission) do
    permission_code { generate(:alphanumstr) }
    description { generate(:alphanumstr) }
    level { ['repository', 'global'].sample }
  end

  factory :json_preference, class: JSONModel(:preference) do
    defaults { build(:json_defaults) }
  end

  factory :json_print_to_pdf_job, class: JSONModel(:print_to_pdf_job) do
    source { create(:json_resource).uri }
  end

  factory :json_range_query, class: JSONModel(:range_query) do
    field { generate(:alphanumstr) }
    from { generate(:yyyy_mm_dd) }
    to { generate(:yyyy_mm_dd) }
  end

  factory :json_rde_template, class: JSONModel(:rde_template) do
    name { generate(:alphanumstr) }
    record_type { ['archival_object', 'digital_object_component'].sample }
    order { [generate(:alphanumstr)] }
    visible { [generate(:alphanumstr)] }
  end

  factory :json_record_tree, class: JSONModel(:record_tree) do
    id { generate(:integer) }
    record_uri { generate(:alphanumstr) }
    title { [nil, generate(:generic_title)].sample }
    suppressed { false }
    publish { generate(:boolean_or_nil) }
    node_type { generate(:alphanumstr) }
  end

  factory :json_report_job, class: JSONModel(:report_job) do
    report_type { ['AssessmentListReport', 'AssessmentRatingReport', 'ResourceDeaccessionsListReport', 'ResourceInstancesListReport', 'ResourceLocationsListReport', 'ResourceRestrictionsListReport', 'ResourcesListReport', 'SubjectListReport', 'LocationHoldingsReport', 'LocationReport', 'ShelflistReport', 'AccessionReport', 'AccessionSubjectsNamesClassificationsListReport', 'AccessionRightsTransferredReport', 'AccessionReceiptReport', 'CreatedAccessionsReport', 'AccessionDeaccessionsListReport', 'AccessionInventoryReport', 'AccessionUnprocessedReport', 'AgentListReport', 'UserGroupsReport', 'DigitalObjectListTableReport', 'DigitalObjectFileVersionsReport'].sample }
    format { ['json', 'csv', 'html', 'pdf', 'rtf'].sample }
  end

  factory :json_repository_with_agent, class: JSONModel(:repository_with_agent) do
    repository { build(:json_repository) }
    agent_representation { build(:json_agent_corporate_entity) }
  end

  factory :json_repository, class: JSONModel(:repository) do
    repo_code { generate(:repo_code) }
    name { generate(:generic_description) }
    org_code { generate(:alphanumstr) }
    image_url { generate(:url) }
    url { generate(:url) }
    country { 'US' }
  end

  factory :json_resource_ordered_records, class: JSONModel(:resource_ordered_records) do
    uris { [{
      'ref' => create(:json_resource).uri
      }] }
  end

  factory :json_resource_tree, class: JSONModel(:resource_tree) do
    id { generate(:integer) }
    record_uri { generate(:alphanumstr) }
    finding_aid_filing_title { nil_or_whatever }
    level { nil_or_whatever }
    component_id { nil_or_whatever }
    instance_types { [generate(:alphanumstr)] }
    containers { [{}] }
    children { [ ] }
  end

  factory :json_resource, class: JSONModel(:resource) do
    title { "Resource #{generate(:html_title)}" }
    id_0 { generate(:alphanumstr) }
    extents { [build(:json_extent)] }
    level { generate(:archival_record_level) }
    lang_materials { [build(:json_lang_material)] }
    dates { [build(:json_date), build(:json_date_single)] }
    finding_aid_description_rules { generate(:finding_aid_description_rules) }
    ead_id { nil_or_whatever }
    finding_aid_date { generate(:alphanumstr) }
    finding_aid_series_statement { generate(:alphanumstr) }
    finding_aid_language { generate(:finding_aid_language) }
    finding_aid_script { generate(:finding_aid_script) }
    finding_aid_language_note { nil_or_whatever }
    finding_aid_note { generate(:alphanumstr) }
    ead_location { generate(:alphanumstr) }
    instances { [ build(:json_instance) ] }
    revision_statements { [build(:json_revision_statement)] }
  end

  factory :json_revision_statement, class: JSONModel(:revision_statement) do
    date { generate(:alphanumstr) }
    description { generate(:alphanumstr) }
  end

  factory :json_rights_restriction, class: JSONModel(:rights_restriction) do
    self.begin { generate(:yyyy_mm_dd) }
    self.end { generate(:yyyy_mm_dd) }
    local_access_restriction_type {[ generate(:restriction_type) ]}
    linked_records { {'ref' => create(:json_resource).uri} }
  end

  factory :json_rights_statement_act, class: JSONModel(:rights_statement_act) do
    act_type { generate(:act_type) }
    restriction { generate(:act_restriction) }
    start_date { generate(:yyyy_mm_dd) }
  end

  factory :json_rights_statement_external_document, class: JSONModel(:rights_statement_external_document) do
    title { "External Document #{generate(:generic_title)}" }
    location { generate(:url) }
    identifier_type { generate(:external_document_identifier_type) }
  end

  factory :json_rights_statement, class: JSONModel(:rights_statement) do
    rights_type { 'copyright' }
    status { generate(:status) }
    jurisdiction { generate(:jurisdiction) }
    start_date { generate(:yyyy_mm_dd) }
  end

  factory :json_structured_date_label, class: JSONModel(:structured_date_label) do
    date_type_structured { "single" }
    date_label { 'existence' }
    structured_date_single { build(:json_structured_date_single) }
    date_certainty { "approximate" }
    date_era { "ce" }
    date_calendar { "gregorian" }
  end

  factory :json_structured_date_range, class: JSONModel(:structured_date_range) do
    begin_date_expression { "Yesterday" }
    begin_date_standardized { "2019-06-01" }
    begin_date_standardized_type { "standard" }
    end_date_expression { "Tomorrow" }
    end_date_standardized { "2019-06-02" }
    end_date_standardized_type { "standard" }
  end

  factory :json_structured_date_single, class: JSONModel(:structured_date_single) do
    date_role { "begin" }
    date_expression { "Yesterday" }
    date_standardized { "2019-06-01" }
    date_standardized_type { "standard" }
  end

  factory :json_sub_container, class: JSONModel(:sub_container) do
    top_container { {:ref => create(:json_top_container).uri} }
    type_2 { sample(JSONModel(:sub_container).schema['properties']['type_2']) }
    indicator_2 { generate(:alphanumstr) }
    barcode_2 { generate(:alphanumstr) }
    type_3 { sample(JSONModel(:sub_container).schema['properties']['type_3']) }
    indicator_3 { generate(:alphanumstr) }
  end

  factory :json_subject, class: JSONModel(:subject) do
    external_ids { [build(:json_external_id)] }
    source { generate(:subject_source) }
    scope_note { generate(:alphanumstr) }
    terms { [build(:json_term)] }
    vocabulary { create(:json_vocabulary).uri }
    authority_id { generate(:url) }
    external_documents { [build(:json_external_document)] }
    metadata_rights_declarations { [build(:json_metadata_rights_declaration)] }
  end

  factory :json_telephone, class: JSONModel(:telephone) do
    number_type { [nil, 'business', 'home', 'cell', 'fax'].sample }
    number { generate(:phone_number) }
    ext { nil_or_whatever }
  end

  factory :json_term, class: JSONModel(:term) do
    term { generate(:generic_term) }
    term_type { generate(:term_type) }
    vocabulary { create(:json_vocabulary).uri }
  end

  factory :json_resource_duplicate_job, class: JSONModel(:resource_duplicate_job) do
    source { generate(:alphanumstr) }
  end

  factory :json_top_container_linker_job, class: JSONModel(:top_container_linker_job) do
    resource_id { generate(:alphanumstr) }
    filename { generate(:alphanumstr) }
    load_type { nil_or_whatever }
    content_type { "text/csv" }
    only_validate { nil_or_whatever }
  end

  factory :json_top_container, class: JSONModel(:top_container) do
    indicator { generate(:alphanumstr) }
    type { generate(:container_type) }
    barcode { SecureRandom.hex }
    ils_holding_id { generate(:alphanumstr) }
    ils_item_id { generate(:alphanumstr) }
    exported_to_ils { Time.now.iso8601 }
  end

  factory :json_trim_whitespace_job, class: JSONModel(:trim_whitespace_job) do
    {}
  end

  factory :json_used_language, class: JSONModel(:used_language) do
    language { generate(:language) }
    script { generate(:script) }
    notes { [build(:json_note_text)] }
  end

  factory :json_user_defined, class: JSONModel(:user_defined) do
    boolean_1 { generate(:boolean_or_nil) }
    boolean_2 { generate(:boolean_or_nil) }
    boolean_3 { generate(:boolean_or_nil) }
    integer_1 { [nil, generate(:number)].sample }
    integer_2 { [nil, generate(:number)].sample }
    integer_3 { [nil, generate(:number)].sample }
    real_1 { [nil, generate(:number)].sample }
    real_2 { [nil, generate(:number)].sample }
    real_3 { [nil, generate(:number)].sample }
    string_1 { nil_or_whatever }
    string_2 { nil_or_whatever }
    string_3 { nil_or_whatever }
    text_1 { nil_or_whatever }
    text_2 { nil_or_whatever }
    text_3 { nil_or_whatever }
    text_4 { nil_or_whatever }
    text_5 { nil_or_whatever }
    date_1 { [nil, generate(:yyyy_mm_dd)].sample }
    date_2 { [nil, generate(:yyyy_mm_dd)].sample }
    date_3 { [nil, generate(:yyyy_mm_dd)].sample }
    enum_1 { [nil, generate(:user_defined_enum_1)].sample }
    enum_2 { [nil, generate(:user_defined_enum_2)].sample }
    enum_3 { [nil, generate(:user_defined_enum_3)].sample }
    enum_4 { [nil, generate(:user_defined_enum_4)].sample }
  end

  factory :json_user, class: JSONModel(:user) do
    username { generate(:username) }
    name { generate(:generic_name) }
  end

  factory :json_vocabulary, class: JSONModel(:vocabulary) do
    name { generate(:vocab_name) }
    ref_id { generate(:vocab_refid) }
  end


  # NOTE: The following factories are not needed for the API docs.
  factory :json_archival_object_nohtml, class: JSONModel(:archival_object) do
    ref_id { generate(:alphanumstr) }
    level { generate(:level) }
    title { "Archival Object #{generate(:generic_title)}" }
    resource { {'ref' => create(:json_resource_nohtml).uri} }
  end

  factory :json_agent_person_full_subrec, class: JSONModel(:agent_person) do
    agent_type { 'agent_person' }
    names { [build(:json_name_person)] }
    dates_of_existence { [build(:json_structured_date_label)] }
    agent_record_controls { [build(:agent_record_control)] }
    agent_alternate_sets { [build(:agent_alternate_set)] }
    agent_conventions_declarations { [build(:agent_conventions_declaration)] }
    agent_sources { [build(:agent_sources)] }
    agent_other_agency_codes { [build(:agent_other_agency_codes)] }
    agent_maintenance_histories { [build(:agent_maintenance_history)] }
    agent_record_identifiers { [build(:agent_record_identifier)] }
    agent_places { [build(:json_agent_place)] }
    agent_occupations { [build(:json_agent_occupation)] }
    agent_functions { [build(:json_agent_function)] }
    agent_topics { [build(:json_agent_topic)] }
    agent_identifiers { [build(:json_agent_identifier)] }
    agent_resources { [build(:json_agent_resource)] }
    agent_genders { [build(:json_agent_gender)] }
    used_languages { [build(:json_used_language)] }
  end

  factory :json_agent_person_merge_destination, class: JSONModel(:agent_person) do
    agent_type { 'agent_person' }
    names { [build(:json_name_person)] }
    dates_of_existence { [build(:json_structured_date_label)] }
    agent_conventions_declarations { [build(:agent_conventions_declaration), build(:agent_conventions_declaration)] }
    agent_record_controls { [build(:agent_record_control)] }
  end

  factory :json_agent_person_merge_candidate, class: JSONModel(:agent_person) do
    agent_type { 'agent_person' }
    names { [build(:json_name_person)] }
    dates_of_existence { [build(:json_structured_date_label)] }
    agent_conventions_declarations { [build(:agent_conventions_declaration), build(:agent_conventions_declaration)] }
    agent_record_controls { [build(:agent_record_control)] }
  end

  factory :json_agent_corporate_entity_full_subrec, class: JSONModel(:agent_corporate_entity) do
    agent_type { 'agent_corporate_entity' }
    names { [build(:json_name_corporate_entity)] }
    agent_contacts { [build(:json_agent_contact)] }
    dates_of_existence { [build(:json_structured_date_label)] }
    agent_record_controls { [build(:agent_record_control)] }
    agent_alternate_sets { [build(:agent_alternate_set)] }
    agent_conventions_declarations { [build(:agent_conventions_declaration)] }
    agent_sources { [build(:agent_sources)] }
    agent_other_agency_codes { [build(:agent_other_agency_codes)] }
    agent_maintenance_histories { [build(:agent_maintenance_history)] }
    agent_record_identifiers { [build(:agent_record_identifier)] }
    agent_places { [build(:json_agent_place)] }
    agent_occupations { [build(:json_agent_occupation)] }
    agent_functions { [build(:json_agent_function)] }
    agent_topics { [build(:json_agent_topic)] }
    agent_identifiers { [build(:json_agent_identifier)] }
    used_languages { [build(:json_used_language)] }
    agent_resources { [build(:json_agent_resource)] }
    notes { [build(:json_note_bioghist),
             build(:json_note_legal_status),
             build(:json_note_mandate),
             build(:json_note_structure_or_genealogy),
             build(:json_note_general_context)] }
  end

  factory :json_agent_software_full_subrec, class: JSONModel(:agent_software) do
    agent_type { 'agent_software' }
    names { [build(:json_name_software)] }
    dates_of_existence { [build(:json_structured_date_label)] }
    agent_places { [build(:json_agent_place)] }
    agent_occupations { [build(:json_agent_occupation)] }
    agent_functions { [build(:json_agent_function)] }
    agent_topics { [build(:json_agent_topic)] }
    agent_identifiers { [build(:json_agent_identifier)] }
    used_languages { [build(:json_used_language)] }
  end

  factory :json_agent_family_full_subrec, class: JSONModel(:agent_family) do
    agent_type { 'agent_family' }
    names { [build(:json_name_family)] }
    dates_of_existence { [build(:json_structured_date_label)] }
    agent_record_controls { [build(:agent_record_control)] }
    agent_alternate_sets { [build(:agent_alternate_set)] }
    agent_conventions_declarations { [build(:agent_conventions_declaration)] }
    agent_sources { [build(:agent_sources)] }
    agent_other_agency_codes { [build(:agent_other_agency_codes)] }
    agent_maintenance_histories { [build(:agent_maintenance_history)] }
    agent_record_identifiers { [build(:agent_record_identifier)] }
    agent_places { [build(:json_agent_place)] }
    agent_occupations { [build(:json_agent_occupation)] }
    agent_functions { [build(:json_agent_function)] }
    agent_topics { [build(:json_agent_topic)] }
    agent_identifiers { [build(:json_agent_identifier)] }
    used_languages { [build(:json_used_language)] }
    agent_resources { [build(:json_agent_resource)] }
  end

  factory :json_note_text_gone_wilde, class: JSONModel(:note_text) do
    content { generate(:wild_markup) }
  end

  factory :json_structured_date_label_range, class: JSONModel(:structured_date_label) do
    date_type_structured { "range" }
    date_label { 'existence' }
    structured_date_range { build(:json_structured_date_range) }
    date_certainty { "approximate" }
    date_era { "ce" }
    date_calendar { "gregorian" }
  end

  factory :json_structured_date_label_range_no_expression, class: JSONModel(:structured_date_label) do
    date_type_structured { "range" }
    date_label { 'existence' }
    structured_date_range { build(:json_structured_date_range_no_expression) }
    date_certainty { "approximate" }
    date_era { "ce" }
    date_calendar { "gregorian" }
  end

  factory :json_structured_date_range_no_expression, class: JSONModel(:structured_date_range) do
    begin_date_standardized { "2019-06-01" }
    begin_date_standardized_type { "standard" }
    end_date_standardized { "2019-06-02" }
    end_date_standardized_type { "not_before" }
  end

  factory :json_date_single, class: JSONModel(:date) do
    date_type { 'single' }
    label { 'creation' }
    self.begin { generate(:yyyy_mm_dd) }
    self.certainty { 'inferred' }
    self.era { 'ce' }
    self.calendar { 'gregorian' }
    expression { generate(:alphanumstr) }
  end

  factory :json_digital_object_unpub_files, class: JSONModel(:digital_object) do
    title { "Digital Object #{generate(:generic_title)}" }
    lang_materials { [build(:json_lang_material)] }
    digital_object_id { generate(:alphanumstr) }
    extents { [build(:json_extent)] }
    file_versions { few_or_none(:json_file_version_unpub) }
    dates { few_or_none(:json_date) }
  end

  factory :json_lang_material_with_note, class: JSONModel(:lang_material) do
    language_and_script { build(:json_language_and_script) }
    notes { [build(:json_note_langmaterial)] }
  end

  factory :json_file_version_unpub, class: JSONModel(:file_version) do
    file_uri { generate(:alphanumstr) }
    use_statement { generate(:use_statement) }
    xlink_actuate_attribute { generate(:xlink_actuate_attribute) }
    xlink_show_attribute { generate(:xlink_show_attribute) }
    file_format_name { generate(:file_format_name) }
    file_format_version { generate(:alphanumstr) }
    file_size_bytes { generate(:number).to_i }
    checksum { generate(:alphanumstr) }
    checksum_method { generate(:checksum_method) }
    publish { false }
  end

  factory :json_instance_digital, class: JSONModel(:instance) do
    instance_type { 'digital_object' }
    digital_object { {'ref' => create(:json_digital_object).uri } }
  end

  factory :json_note_multipart_gone_wilde, class: JSONModel(:note_multipart) do
    type { generate(:multipart_note_type)}
    subnotes { [ build(:json_note_text_gone_wilde, :publish => true) ] }
  end

  factory :json_resource_nohtml, class: JSONModel(:resource) do
    title { "Resource #{generate(:generic_title)}" }
    id_0 { generate(:alphanumstr) }
    extents { [build(:json_extent)] }
    level { generate(:archival_record_level) }
    lang_materials { [build(:json_lang_material)] }
    dates { [build(:json_date), build(:json_date_single)] }
    finding_aid_description_rules { generate(:finding_aid_description_rules) }
    ead_id { nil_or_whatever }
    finding_aid_date { generate(:alphanumstr) }
    finding_aid_series_statement { generate(:alphanumstr) }
    finding_aid_language { generate(:finding_aid_language) }
    finding_aid_script { generate(:finding_aid_script) }
    finding_aid_language_note { nil_or_whatever }
    finding_aid_note { generate(:alphanumstr) }
    ead_location { generate(:alphanumstr) }
    instances { [ build(:json_instance) ] }
    revision_statements { [build(:json_revision_statement)] }
  end

  factory :json_accession_job, class: JSONModel(:job) do
    job { build(:json_acc_job) }
  end

  factory :json_acc_job, class: JSONModel(:report_job) do
    report_type { 'AccessionReport' }
    format { 'json' }
  end

  factory :json_deaccession_job, class: JSONModel(:job) do
    job { build(:json_deacc_job) }
  end

  factory :json_deacc_job, class: JSONModel(:report_job) do
    report_type { 'AccessionDeaccessionsListReport' }
    format { 'json' }
  end

  factory :json_agent_job, class: JSONModel(:job) do
    job { build(:json_agt_job) }
  end

  factory :json_agt_job, class: JSONModel(:report_job) do
    report_type { 'AgentListReport' }
    format { 'json' }
  end

  factory :json_dig_obj_file_job, class: JSONModel(:job) do
    job { build(:json_do_file_job) }
  end

  factory :json_do_file_job, class: JSONModel(:report_job) do
    report_type { 'DigitalObjectFileVersionsReport' }
    format { 'json' }
  end

  factory :json_location_job, class: JSONModel(:job) do
    job { build(:json_loc_job) }
  end

  factory :json_loc_job, class: JSONModel(:report_job) do
    report_type { 'LocationReport' }
    format { 'json' }
  end

  factory :json_resource_deacc_job, class: JSONModel(:job) do
    job { build(:json_res_deacc_job) }
  end

  factory :json_res_deacc_job, class: JSONModel(:report_job) do
    report_type { 'ResourceDeaccessionsListReport' }
    format { 'json' }
  end

  factory :json_resource_restrict_job, class: JSONModel(:job) do
    job { build(:json_res_res_job) }
  end

  factory :json_res_res_job, class: JSONModel(:report_job) do
    report_type { 'ResourceRestrictionsListReport' }
    format { 'json' }
  end

  factory :json_unproc_accession_job, class: JSONModel(:job) do
    job { build(:json_unp_acc_job) }
  end

  factory :json_unp_acc_job, class: JSONModel(:report_job) do
    report_type { 'UnprocessedAccessionsReport' }
    format { 'json' }
  end

  factory :json_subject_list_job, class: JSONModel(:job) do
    job { build(:json_sub_list_job) }
  end

  factory :json_sub_list_job, class: JSONModel(:report_job) do
    report_type { 'SubjectListReport' }
    format { 'json' }
  end

  factory :json_subrecord_requirement, class: JSONModel(:subrecord_requirement) do
    property { 'metadata_rights_declarations' }
    record_type { 'metadata_rights_declaration' }
    required_fields { %w(descriptive_note) }
    required { true }
  end

  factory :json_required_fields, class: JSONModel(:required_fields) do
    record_type { 'archival_object' }
    subrecord_requirements { [build(:json_subrecord_requirement)] }
  end
end
