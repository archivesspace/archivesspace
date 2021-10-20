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

  sequence(:alphanumstr) { (0..4).map { rand(3)==1?rand(1000):(65 + rand(25)).chr }.join }
  sequence(:ark_name) { sample(JSONModel(:ark_name).schema['properties']) }
  sequence(:number) { rand(100).to_s }

  sequence(:agent_role) { sample(JSONModel(:event).schema['properties']['linked_agents']['items']['properties']['role']) }
  sequence(:record_role) { sample(JSONModel(:event).schema['properties']['linked_records']['items']['properties']['role']) }

  sequence(:date_type) { sample(JSONModel(:date).schema['properties']['date_type']) }
  sequence(:date_label) { sample(JSONModel(:date).schema['properties']['label']) }

  sequence(:multipart_note_type) { sample(JSONModel(:note_multipart).schema['properties']['type'])}
  sequence(:digital_object_note_type) { sample(JSONModel(:note_digital_object).schema['properties']['type'])}
  sequence(:langmaterial_note_type) { sample(JSONModel(:note_langmaterial).schema['properties']['type'])}
  sequence(:rights_statement_note_type) { sample(JSONModel(:note_rights_statement).schema['properties']['type'])}
  sequence(:rights_statement_act_note_type) { sample(JSONModel(:note_rights_statement_act).schema['properties']['type'])}
  sequence(:singlepart_note_type) { sample(JSONModel(:note_singlepart).schema['properties']['type'])}
  sequence(:note_index_type) { sample(JSONModel(:note_index).schema['properties']['type'])}
  sequence(:note_index_item_type) { sample(JSONModel(:note_index_item).schema['properties']['type'])}
  sequence(:note_bibliography_type) { sample(JSONModel(:note_bibliography).schema['properties']['type'])}
  sequence(:orderedlist_enumeration) { sample(JSONModel(:note_orderedlist).schema['properties']['enumeration']) }
  sequence(:chronology_item) { {'event_date' => nil_or_whatever, 'events' => (0..rand(3)).map { FactoryBot.generate(:alphanumstr) } } }

  sequence(:event_type) { sample(JSONModel(:event).schema['properties']['event_type']) }
  sequence(:extent_type) { sample(JSONModel(:extent).schema['properties']['extent_type']) }
  sequence(:portion) { sample(JSONModel(:extent).schema['properties']['portion']) }
  sequence(:language) { sample(JSONModel(:language_and_script).schema['properties']['language']) }
  sequence(:script) { sample(JSONModel(:language_and_script).schema['properties']['script']) }
  sequence(:instance_type) { sample(JSONModel(:instance).schema['properties']['instance_type'], ['digital_object']) }

  sequence(:rights_type) { sample(JSONModel(:rights_statement).schema['properties']['rights_type']) }
  sequence(:status) { sample(JSONModel(:rights_statement).schema['properties']['status']) }
  sequence(:jurisdiction) { sample(JSONModel(:rights_statement).schema['properties']['jurisdiction']) }
  sequence(:other_rights_basis) { sample(JSONModel(:rights_statement).schema['properties']['other_rights_basis']) }
  sequence(:act_type) { sample(JSONModel(:rights_statement_act).schema['properties']['act_type']) }
  sequence(:act_restriction) { sample(JSONModel(:rights_statement_act).schema['properties']['restriction']) }
  sequence(:external_document_identifier_type) { sample(JSONModel(:rights_statement_external_document).schema['properties']['identifier_type']) }

  sequence(:container_location_status) { sample(JSONModel(:container_location).schema['properties']['status']) }
  sequence(:temporary_location_type) { sample(JSONModel(:location).schema['properties']['temporary']) }

  sequence(:use_statement) { sample(JSONModel(:file_version).schema['properties']['use_statement']) }
  sequence(:checksum_method) { sample(JSONModel(:file_version).schema['properties']['checksum_method']) }
  sequence(:xlink_actuate_attribute) { sample(JSONModel(:file_version).schema['properties']['xlink_actuate_attribute']) }
  sequence(:xlink_show_attribute) { sample(JSONModel(:file_version).schema['properties']['xlink_show_attribute']) }
  sequence(:file_format_name) { sample(JSONModel(:file_version).schema['properties']['file_format_name']) }
  sequence(:archival_record_level) { sample(JSONModel(:resource).schema['properties']['level'], ['otherlevel']) }
  sequence(:finding_aid_description_rules) { sample(JSONModel(:resource).schema['properties']['finding_aid_description_rules']) }
  sequence(:finding_aid_language) { sample(JSONModel(:resource).schema['properties']['finding_aid_language']) }
  sequence(:finding_aid_script) { sample(JSONModel(:resource).schema['properties']['finding_aid_script']) }

  sequence(:relator) { sample(JSONModel(:abstract_archival_object).schema['properties']['linked_agents']['items']['properties']['relator']) }
  sequence(:subject_source) { sample(JSONModel(:subject).schema['properties']['source']) }
  sequence(:resource_agent_role) { sample(JSONModel(:abstract_archival_object).schema['properties']['linked_agents']['items']['properties']['role']) }

  sequence(:vocab_name) {|n| "Vocabulary #{n} - #{Time.now}" }
  sequence(:vocab_refid) {|n| "vocab_ref_#{n} - #{Time.now}"}

  sequence(:downtown_address) { "#{rand(200)} #{%w(E W).sample} #{(4..9).to_a.sample}th Street" }

  sequence(:name_rule) { sample(JSONModel(:abstract_name).schema['properties']['rules']) }
  sequence(:name_source) { sample(JSONModel(:abstract_name).schema['properties']['source']) }

  sequence(:generic_name) {|n| "Name Number #{n}"}
  sequence(:sort_name) { |n| "SORT #{('a'..'z').to_a[rand(26)]} - #{n}" }

  sequence(:term) { |n| "Term #{n}" }
  sequence(:term_type) { sample(JSONModel(:term).schema['properties']['term_type']) }

  sequence(:url) {|n| "http://www.example-#{n}-#{Time.now.to_i}.com"}
  sequence(:yyyy_mm_dd) { Time.at(rand * Time.now.to_i).to_s.sub(/\s.*/, '') }
  sequence(:generic_title) { |n| "Title: #{n}"}
  sequence(:generic_description) {|n| "Description: #{n}"}
  sequence(:username) {|n| "username_#{n}-#{Time.now.to_i}"}

  factory :json_accession, class: JSONModel(:accession) do
    id_0 { generate(:alphanumstr) }
    id_1 { generate(:alphanumstr) }
    id_2 { generate(:alphanumstr) }
    id_3 { generate(:alphanumstr) }
    title { "Accession " + generate(:generic_title) }
    content_description { generate(:generic_description) }
    condition_description { generate(:generic_description) }
    accession_date { generate(:yyyy_mm_dd) }
  end

  factory :json_telephone, class: JSONModel(:telephone) do
    number_type { [nil, 'business', 'home', 'cell', 'fax'].sample }
    number { generate(:phone_number) }
    ext { [nil, generate(:alphanumstr)].sample }
  end

  factory :json_agent_contact, class: JSONModel(:agent_contact) do
    name { generate(:generic_name) }
    telephones { [build(:json_telephone)] }
    address_1 { [nil, generate(:alphanumstr)].sample }
    address_2 { [nil, generate(:alphanumstr)].sample }
    address_3 { [nil, generate(:alphanumstr)].sample }
    city { [nil, generate(:alphanumstr)].sample }
    region { [nil, generate(:alphanumstr)].sample }
    country { [nil, generate(:alphanumstr)].sample }
    post_code { [nil, generate(:alphanumstr)].sample }
    fax { [nil, generate(:alphanumstr)].sample }
    email { [nil, generate(:alphanumstr)].sample }
    email_signature { [nil, generate(:alphanumstr)].sample }
    notes { [build(:json_note_contact_note)] }
    is_representative { false }
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

  factory :json_agent_person, class: JSONModel(:agent_person) do
    agent_type { 'agent_person' }
    names { [build(:json_name_person)] }
    dates_of_existence { [build(:json_structured_date_label)] }
  end

  factory :json_agent_software, class: JSONModel(:agent_software) do
    agent_type { 'agent_software' }
    names { [build(:json_name_software)] }
    dates_of_existence { [build(:json_structured_date_label)] }
  end

  factory :json_archival_object, class: JSONModel(:archival_object) do
    ref_id { generate(:alphanumstr) }
    level { generate(:level) }
    title { "Archival Object #{generate(:generic_title)}" }
    resource { {'ref' => create(:json_resource).uri} }
  end

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

  factory :json_agent_person_merge_target, class: JSONModel(:agent_person) do
    agent_type { 'agent_person' }
    names { [build(:json_name_person)] }
    dates_of_existence { [build(:json_structured_date_label)] }
    agent_conventions_declarations { [build(:agent_conventions_declaration), build(:agent_conventions_declaration)] }
    agent_record_controls { [build(:agent_record_control)] }
  end

  factory :json_agent_person_merge_victim, class: JSONModel(:agent_person) do
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

  factory :json_archival_object_normal, class: JSONModel(:archival_object) do
    ref_id { generate(:alphanumstr) }
    level { generate(:level) }
    title { "Archival Object #{generate(:generic_title)}" }
    extents { few_or_none(:json_extent) }
    dates { few_or_none(:json_date) }
    resource { {'ref' => create(:json_resource).uri} }
  end

  factory :json_classification, class: JSONModel(:classification) do
    identifier { generate(:alphanumstr) }
    title { "Classification #{generate(:generic_title)}" }
    description { generate(:generic_description) }
  end

  factory :json_classification_term, class: JSONModel(:classification_term) do
    identifier { generate(:alphanumstr) }
    title { "Classification #{generate(:generic_title)}" }
    description { generate(:generic_description) }
    classification { {'ref' => create(:json_classification).uri} }
  end

  factory :json_note_index, class: JSONModel(:note_index) do
    type { generate(:note_index_type)}
    content { [ generate(:alphanumstr), generate(:alphanumstr) ] }
    items { [ build(:json_note_index_item), build(:json_note_index_item) ] }
  end

  factory :json_note_index_item, class: JSONModel(:note_index_item) do
    value { generate(:alphanumstr) }
    #reference { generate(:alphanumstr) }
    #reference_text { generate(:alphanumstr) }
    type { generate(:note_index_item_type) }
  end

  factory :json_note_bibliography, class: JSONModel(:note_bibliography) do
    label { [ generate(:alphanumstr), nil].sample }
    content { [generate(:wild_markup)] }
    items { [generate(:alphanumstr)] }
    type { [ generate(:note_bibliography_type), nil].sample }
  end

  factory :json_note_bioghist, class: JSONModel(:note_bioghist) do
    label { generate(:alphanumstr) }
    subnotes { [ build(:json_note_outline), build(:json_note_text) ] }
  end

  factory :json_note_general_context, class: JSONModel(:note_general_context) do
    label { generate(:alphanumstr) }
    subnotes { [ build(:json_note_outline), build(:json_note_text) ] }
  end

  factory :json_note_mandate, class: JSONModel(:note_mandate) do
    label { generate(:alphanumstr) }
    subnotes { [ build(:json_note_text) ] }
  end

  factory :json_note_legal_status, class: JSONModel(:note_legal_status) do
    label { generate(:alphanumstr) }
    subnotes { [ build(:json_note_text) ] }
  end

  factory :json_note_structure_or_genealogy, class: JSONModel(:note_structure_or_genealogy) do
    label { generate(:alphanumstr) }
    subnotes { [ build(:json_note_text) ] }
  end

  factory :json_note_contact_note, class: JSONModel(:note_contact_note) do
    date_of_contact { generate(:alphanumstr) }
    contact_notes { generate(:alphanumstr) }
  end

  factory :json_note_outline, class: JSONModel(:note_outline) do
    levels { [ build(:json_note_outline_level) ] }
  end

  factory :json_note_text, class: JSONModel(:note_text) do
    content { generate(:alphanumstr) }
  end

  factory :json_note_text_gone_wilde, class: JSONModel(:note_text) do
    content { generate(:wild_markup) }
  end

  factory :json_note_orderedlist, class: JSONModel(:note_orderedlist) do
    title { nil_or_whatever }
    enumeration { generate(:orderedlist_enumeration) }
    items { (0..rand(3)).map { generate(:alphanumstr) } }
  end

  factory :json_note_definedlist, class: JSONModel(:note_definedlist) do
    title { nil_or_whatever }
    items { (0..rand(3)).map { {:label => generate(:alphanumstr), :value => generate(:alphanumstr) } } }
  end

  factory :json_note_abstract, class: JSONModel(:note_abstract) do
    content { (0..rand(3)).map { generate(:good_markup) } }
  end

  factory :json_note_citation, class: JSONModel(:note_citation) do
    content { (0..rand(3)).map { generate(:good_markup) } }
    xlink { Hash[%w(actuate arcrole href role show title type).map {|i| [i, i]}] }
  end

  factory :json_note_chronology, class: JSONModel(:note_chronology) do
    title { nil_or_whatever }
    items { (0..rand(3)).map { generate(:chronology_item) } }
  end

  factory :json_note_outline_level, class: JSONModel(:note_outline_level) do
    items { [ generate(:alphanumstr) ] }
  end

  factory :json_top_container, class: JSONModel(:top_container) do
    indicator { generate(:alphanumstr) }
    type { generate(:container_type) }
    barcode { SecureRandom.hex }
    ils_holding_id { generate(:alphanumstr) }
    ils_item_id { generate(:alphanumstr) }
    exported_to_ils { Time.now.iso8601 }
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

  factory :json_location_profile, class: JSONModel(:location_profile) do
    name { generate(:alphanumstr) }
    dimension_units { sample(JSONModel(:location_profile).schema['properties']['dimension_units']) }
    depth { rand(100).to_s }
    height { rand(100).to_s }
    width { rand(100).to_s }
  end

  factory :json_location_function, class: JSONModel(:location_function) do
    location_function_type { sample(JSONModel(:location_function).schema['properties']['location_function_type']) }
  end

  factory :json_sub_container, class: JSONModel(:sub_container) do
    top_container { {:ref => create(:json_top_container).uri} }
    type_2 { sample(JSONModel(:sub_container).schema['properties']['type_2']) }
    indicator_2 { generate(:alphanumstr) }
    barcode_2 { generate(:alphanumstr) }
    type_3 { sample(JSONModel(:sub_container).schema['properties']['type_3']) }
    indicator_3 { generate(:alphanumstr) }
  end

  factory :json_structured_date_label, class: JSONModel(:structured_date_label) do
    date_type_structured { "single" }
    date_label { 'existence' }
    structured_date_single { build(:json_structured_date_single) }
    date_certainty { "approximate" }
    date_era { "ce" }
    date_calendar { "gregorian" }
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


  factory :json_structured_date_single, class: JSONModel(:structured_date_single) do
    date_role { "begin" }
    date_expression { "Yesterday" }
    date_standardized { "2019-06-01" }
    date_standardized_type { "standard" }
  end

  factory :json_structured_date_range, class: JSONModel(:structured_date_range) do
    begin_date_expression { "Yesterday" }
    begin_date_standardized { "2019-06-01" }
    begin_date_standardized_type { "standard" }
    end_date_expression { "Tomorrow" }
    end_date_standardized { "2019-06-02" }
    end_date_standardized_type { "standard" }
  end

  factory :json_structured_date_range_no_expression, class: JSONModel(:structured_date_range) do
    begin_date_standardized { "2019-06-01" }
    begin_date_standardized_type { "standard" }
    end_date_standardized { "2019-06-02" }
    end_date_standardized_type { "not_before" }
  end


  factory :json_date, class: JSONModel(:date) do
    date_type { generate(:date_type) }
    label { 'creation' }
    self.begin { generate(:yyyy_mm_dd) }
    self.end { self.begin }
    self.certainty { 'inferred' }
    self.era { 'ce' }
    self.calendar { 'gregorian' }
    expression { generate(:alphanumstr) }
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


  factory :json_deaccession, class: JSONModel(:deaccession) do
    scope { "whole" }
    description { generate(:generic_description) }
    date { build(:json_date) }
  end

  factory :json_digital_object, class: JSONModel(:digital_object) do
    title { "Digital Object #{generate(:generic_title)}" }
    lang_materials { [build(:json_lang_material)] }
    digital_object_id { generate(:alphanumstr) }
    extents { [build(:json_extent)] }
    file_versions { few_or_none(:json_file_version) }
    dates { few_or_none(:json_date) }
  end

  factory :json_digital_object_unpub_files, class: JSONModel(:digital_object) do
    title { "Digital Object #{generate(:generic_title)}" }
    lang_materials { [build(:json_lang_material)] }
    digital_object_id { generate(:alphanumstr) }
    extents { [build(:json_extent)] }
    file_versions { few_or_none(:json_file_version_unpub) }
    dates { few_or_none(:json_date) }
  end

  factory :json_digital_object_no_lang, class: JSONModel(:digital_object) do
    title { "Digital Object #{generate(:generic_title)}" }
    digital_object_id { generate(:alphanumstr) }
    extents { [build(:json_extent)] }
    file_versions { few_or_none(:json_file_version) }
    dates { few_or_none(:json_date) }
  end

  factory :json_digital_object_component, class: JSONModel(:digital_object_component) do
    component_id { generate(:alphanumstr) }
    title { "Digital Object Component #{generate(:generic_title)}" }
    digital_object { {'ref' => create(:json_digital_object).uri} }
    position { rand(0..10) }
    has_unpublished_ancestor { rand(2) == 0 }
  end

  factory :json_digital_object_component_pub_ancestor, class: JSONModel(:digital_object_component) do
    component_id { generate(:alphanumstr) }
    title { "Digital Object Component #{generate(:generic_title)}" }
    digital_object { {'ref' => create(:json_digital_object).uri} }
    label { generate(:alphanumstr) }
    display_string { generate(:alphanumstr) }
    file_versions { few_or_none(:json_file_version) }
    position { 5 }
    has_unpublished_ancestor { false }
  end

  factory :json_digital_object_component_unpub_ancestor, class: JSONModel(:digital_object_component) do
    component_id { generate(:alphanumstr) }
    title { "Digital Object Component #{generate(:generic_title)}" }
    digital_object { {'ref' => create(:json_digital_object).uri} }
    label { generate(:alphanumstr) }
    display_string { generate(:alphanumstr) }
    file_versions { few_or_none(:json_file_version) }
    position { 1 }
    has_unpublished_ancestor { true }
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

  factory :json_lang_material, class: JSONModel(:lang_material) do
    language_and_script { build(:json_language_and_script) }
  end

  factory :json_lang_material_with_note, class: JSONModel(:lang_material) do
    language_and_script { build(:json_language_and_script) }
    notes { [build(:json_note_langmaterial)] }
  end

  factory :json_language_and_script, class: JSONModel(:language_and_script) do
    language { generate(:language) }
    script { generate(:script) }
  end

  factory :json_used_language, class: JSONModel(:used_language) do
    language { generate(:language) }
    script { generate(:script) }
    notes { [build(:json_note_text)] }
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

  factory :json_external_document, class: JSONModel(:external_document) do
    title { "External Document #{generate(:generic_title)}" }
    location { generate(:url) }
  end

  factory :json_group, class: JSONModel(:group) do
    group_code { generate(:alphanumstr) }
    description { generate(:generic_description) }
  end

  factory :json_instance, class: JSONModel(:instance) do
    instance_type { generate(:instance_type) }
    sub_container { build(:json_sub_container) }
  end

  factory :json_instance_digital, class: JSONModel(:instance) do
    instance_type { 'digital_object' }
    digital_object { {'ref' => create(:json_digital_object).uri } }
  end


  factory :json_location, class: JSONModel(:location) do
    building { generate(:downtown_address) }
    floor { "#{rand(13)}" }
    room { "#{rand(20)}" }
    area { %w(Back Front).sample }
    barcode { generate(:barcode) }
    temporary { generate(:temporary_location_type) }
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

  factory :json_name_person_no_date, class: JSONModel(:name_person) do
    rules { generate(:name_rule) }
    source { generate(:name_source) }
    primary_name { generate(:generic_name) }
    sort_name { generate(:sort_name) }
    name_order { %w(direct inverted).sample }
    number { generate(:alphanumstr) }
    sort_name_auto_generate { true }
    qualifier { generate(:alphanumstr) }
    fuller_form { generate(:alphanumstr) }
    prefix { generate(:alphanumstr) }
    title { generate(:alphanumstr) }
    suffix { generate(:alphanumstr) }
    rest_of_name { generate(:alphanumstr) }
    authority_id { generate(:url) }
  end

  factory :json_name_person_parallel, class: JSONModel(:parallel_name_person) do
    primary_name { generate(:generic_name) }
    name_order { %w(direct inverted).sample }
    number { generate(:alphanumstr) }
    qualifier { generate(:alphanumstr) }
    use_dates { [build(:json_structured_date_label)] }
    dates { generate(:alphanumstr) }
    fuller_form { generate(:alphanumstr) }
    prefix { [nil, generate(:alphanumstr)].sample }
    title { [nil, generate(:alphanumstr)].sample }
    suffix { [nil, generate(:alphanumstr)].sample }
    rest_of_name { [nil, generate(:alphanumstr)].sample }
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

  factory :json_collection_management, class: JSONModel(:collection_management) do
  end

  factory :json_note_singlepart, class: JSONModel(:note_singlepart) do
    type { generate(:singlepart_note_type)}
    content { [ generate(:alphanumstr), generate(:alphanumstr) ] }
  end

  factory :json_note_multipart, class: JSONModel(:note_multipart) do
    type { generate(:multipart_note_type)}
    subnotes { [ build(:json_note_text, :publish => true) ] }
  end

  factory :json_note_multipart_gone_wilde, class: JSONModel(:note_multipart) do
    type { generate(:multipart_note_type)}
    subnotes { [ build(:json_note_text_gone_wilde, :publish => true) ] }
  end

  factory :json_note_digital_object, class: JSONModel(:note_digital_object) do
    type { generate(:digital_object_note_type)}
    content { [ generate(:string), generate(:string) ] }
  end

  factory :json_note_langmaterial, class: JSONModel(:note_langmaterial) do
    type { generate(:langmaterial_note_type)}
    content { [ generate(:string), generate(:string) ] }
  end

  factory :json_note_rights_statement, class: JSONModel(:note_rights_statement) do
    type { generate(:rights_statement_note_type)}
    content { [ generate(:string), generate(:string) ] }
  end

  factory :json_note_rights_statement_act, class: JSONModel(:note_rights_statement_act) do
    type { generate(:rights_statement_act_note_type)}
    content { [ generate(:string), generate(:string) ] }
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

  factory :json_resource_blank_ead_location, class: JSONModel(:resource) do
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
    ead_location { nil }
    instances { [ build(:json_instance) ] }
    revision_statements { [build(:json_revision_statement)] }
  end

  factory :json_revision_statement, class: JSONModel(:revision_statement) do
    date { generate(:alphanumstr) }
    description { generate(:alphanumstr) }
  end

  factory :json_repository, class: JSONModel(:repository) do
    repo_code { generate(:repo_code) }
    name { generate(:generic_description) }
    org_code { generate(:alphanumstr) }
    image_url { generate(:url) }
    url { generate(:url) }
    country { 'US' }
  end

  factory :json_repository_without_country, class: JSONModel(:repository) do
    repo_code { generate(:repo_code) }
    name { generate(:generic_description) }
    org_code { generate(:alphanumstr) }
    image_url { generate(:url) }
    url { generate(:url) }
    country { nil }
  end

  factory :json_repository_us, class: JSONModel(:repository) do
    repo_code { generate(:repo_code) }
    name { generate(:generic_description) }
    org_code { generate(:alphanumstr) }
    image_url { generate(:url) }
    url { generate(:url) }
    country { 'US' }
  end

  factory :json_repository_not_us, class: JSONModel(:repository) do
    repo_code { generate(:repo_code) }
    name { generate(:generic_description) }
    org_code { generate(:alphanumstr) }
    image_url { generate(:url) }
    url { generate(:url) }
    country { 'TH' }
  end

  factory :json_repository_with_agent, class: JSONModel(:repository_with_agent) do
    repository { build(:json_repository) }
    agent_representation { build(:json_agent_corporate_entity) }
  end

  factory :json_repository_no_org_code, class: JSONModel(:repository) do
    repo_code { generate(:repo_code) }
    name { generate(:generic_description) }
    image_url { generate(:url) }
    url { generate(:url) }
    country { 'US' }
  end

  factory :json_repository_parent_org, class: JSONModel(:repository) do
    repo_code { generate(:repo_code) }
    name { generate(:generic_description) }
    org_code { generate(:alphanumstr) }
    image_url { generate(:url) }
    parent_institution_name { generate(:alphanumstr) }
    url { generate(:url) }
    country { 'US' }
  end

  # may need factories for each rights type
  factory :json_rights_statement, class: JSONModel(:rights_statement) do
    rights_type { 'copyright' }
    status { generate(:status) }
    jurisdiction { generate(:jurisdiction) }
    start_date { generate(:yyyy_mm_dd) }
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

  factory :json_subject, class: JSONModel(:subject) do
    terms { [build(:json_term)] }
    vocabulary { create(:json_vocabulary).uri }
    authority_id { generate(:url) }
    scope_note { generate(:alphanumstr) }
    source { generate(:subject_source) }
  end

  factory :json_term, class: JSONModel(:term) do
    term { generate(:term) }
    term_type { generate(:term_type) }
    vocabulary { create(:json_vocabulary).uri }
  end

  factory :json_user, class: JSONModel(:user) do
    username { generate(:username) }
    name { generate(:generic_name) }
  end

  factory :json_vocabulary, class: JSONModel(:vocabulary) do
    name { generate(:vocab_name) }
    ref_id { generate(:vocab_refid) }
  end

  factory :json_job, class: JSONModel(:job) do
    job { build(:json_import_job) }
  end

  factory :json_import_job, class: JSONModel(:import_job) do
    import_type { ['marcxml', 'ead_xml', 'eac_xml'].sample }
    filenames { (0..3).map { generate(:alphanumstr) } }
  end

  factory :json_container_labels_job, class: JSONModel(:container_labels_job) do
    source  { create(:json_resource).uri }
  end

  factory :json_print_to_pdf_job, class: JSONModel(:print_to_pdf_job) do
    source  { create(:json_resource).uri }
  end

  factory :json_top_container_linker_job, class: JSONModel(:top_container_linker_job) do
    filename  { generate(:alphanumstr) }
    content_type { "text/csv" }
  end

  factory :json_generate_slugs_job, class: JSONModel(:generate_slugs_job) do
  end

  factory :json_generate_arks_job, class: JSONModel(:generate_arks_job) do
  end

  factory :json_find_and_replace_job, class: JSONModel(:find_and_replace_job) do
    find { "/foo/" }
    replace { "bar" }
    record_type { "extent" }
    property { "container_summary" }
    base_record_uri { "repositories/2/resources/1" }
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

  factory :json_preference, class: JSONModel(:preference) do
    defaults { build(:json_defaults) }
  end

  factory :json_defaults, class: JSONModel(:defaults) do
    show_suppressed { false }
    publish { false }
  end

  factory :json_assessment, class: JSONModel(:assessment) do
    survey_begin { generate(:yyyy_mm_dd) }
    surveyed_extent { generate(:alphanumstr) }
  end

  factory :json_oai_config, class: JSONModel(:oai_config) do
    oai_record_prefix { 'archivesspace:oai' }
    oai_admin_email { 'oairecord@example.org' }
    oai_repository_name { 'ArchivesSpace OAI Repo' }
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

  factory :json_custom_report_template, class: JSONModel(:custom_report_template) do
    name { "template" }
    description { "good template" }
    data { {fields: {foo: {include: 1}} }.to_json }
    limit { 10 }
  end
end
