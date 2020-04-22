require 'factory_bot'
require 'spec/lib/factory_bot_helpers'

FactoryBot.define do

  def JSONModel(key)
    JSONModel::JSONModel(key)
  end

  to_create{|instance| instance.save}

  sequence(:repo_code) {|n| "ASPACE REPO #{n} -- #{rand(1000000)}"}
  sequence(:username) {|n| "username_#{n}"}

  sequence(:good_markup) { "<p>I'm</p><p>GOOD</p><p>#{ FactoryBot.generate(:alphanumstr)}</p>" }
  sequence(:whack_markup) { "I'm <p><br/>WACK " + FactoryBot.generate(:alphanumstr) }
  sequence(:wild_markup) { "<p> I AM \n WILD \n ! \n ! " + FactoryBot.generate(:alphanumstr) + "</p>" }
  sequence(:string) { FactoryBot.generate(:alphanumstr) }
  sequence(:generic_title) { |n| "Title: #{n}"}
  sequence(:html_title) { |n| "Title: <emph render='italic'>#{n}</emph>"}
  sequence(:generic_description) {|n| "Description: #{n}"}
  sequence(:container_type) {|n| 'box'}

  sequence(:phone_number) { (3..5).to_a[rand(3)].times.map { (3..5).to_a[rand(3)].times.map { rand(9) }.join }.join(' ') }
  sequence(:yyyy_mm_dd) { Time.at(rand * Time.now.to_i).to_s.sub(/\s.*/, '') }
  sequence(:hh_mm) { t = Time.now; "#{t.hour}:#{t.min}" }
  sequence(:barcode) { 20.times.map { rand(2)}.join }
  sequence(:indicator) { (2+rand(3)).times.map { (2+rand(3)).times.map {rand(9)}.join }.join('-') }

  sequence(:level) { %w(series subseries item)[rand(3)] }


  # AS Models
  if defined? ASModel
    factory :unselected_repo, class: Repository do
      json_schema_version { 1 }
      repo_code { generate(:repo_code) }
      name { generate(:generic_description) }
      agent_representation_id { 1 }
    end

    factory :repo, class: Repository do
      json_schema_version { 1 }
      repo_code { generate(:repo_code) }
      name { generate(:generic_description) }
      agent_representation_id { 1 }
      org_code { generate(:alphanumstr) }
      image_url { generate(:url) }
      publish { 1 }
      country { 'US' }
      after(:create) do |r|
        $repo_id = r.id
        $repo = JSONModel.JSONModel(:repository).uri_for(r.id)
        JSONModel.set_repository($repo_id)
        RequestContext.put(:repo_id, $repo_id)
      end
    end

    factory :agent_corporate_entity, class: AgentCorporateEntity do
      json_schema_version { 1 }
      after(:create) do |a|
        a.add_name_corporate_entity(:rules => generate(:name_rule),
                                    :primary_name => generate(:generic_name),
                                    :sort_name => generate(:sort_name),
                                    :sort_name_auto_generate => 1,
                                    :is_display_name => 1,
                                    :authorized => 1,
                                    :json_schema_version => 1)
        a.add_agent_contact(:name => generate(:generic_name),
                            :address_1 => [nil, generate(:alphanumstr)].sample,
                            :address_2 => [nil, generate(:alphanumstr)].sample,
                            :address_3 => [nil, generate(:alphanumstr)].sample,
                            :city => [nil, generate(:alphanumstr)].sample,
                            :region => [nil, generate(:alphanumstr)].sample,
                            :country => [nil, generate(:alphanumstr)].sample,
                            :post_code => [nil, generate(:alphanumstr)].sample,
                            #:telephones => [nil, build(:json_telephone)].sample,
                            :email => [nil, generate(:alphanumstr)].sample,
                            :email_signature => [nil, generate(:alphanumstr)].sample,
                            :note => [nil, generate(:alphanumstr)].sample,
                            :json_schema_version => 1)
      end
    end

    factory :user, class: User do
      json_schema_version { 1 }
      # before(:create) { agent = create(:json_agent_person) }

      username { generate(:username) }
      name { generate(:generic_name) }
      agent_record_type { :agent_person }
      agent_record_id {JSONModel(:agent_person).id_for(create(:json_agent_person).uri)}
      source { 'local' }
    end

    factory :accession do
      json_schema_version { 1 }
      id_0 { generate(:alphanumstr) }
      id_1 { generate(:alphanumstr) }
      id_2 { generate(:alphanumstr) }
      id_3 { generate(:alphanumstr) }
      title { "Accession " + generate(:generic_title) }
      content_description { generate(:generic_description) }
      condition_description { generate(:generic_description) }
      accession_date { generate(:yyyy_mm_dd) }
    end

    factory :resource do
      json_schema_version { 1 }
      title { generate(:generic_title) }
      id_0 { generate(:alphanumstr) }
      id_1 { generate(:alphanumstr) }
      level { generate(:archival_record_level) }
    end

    factory :extent do
      json_schema_version { 1 }
      portion { generate(:portion) }
      number { generate(:number) }
      extent_type { generate(:extent_type) }
      resource_id { nil }
      archival_object_id { nil }
      dimensions { generate(:alphanumstr) }
      physical_details { generate(:alphanumstr) }
    end

    factory :archival_object do
      json_schema_version { 1 }
      title { generate(:generic_title) }
      repo_id { nil }
      ref_id { generate(:alphanumstr) }
      level { generate(:archival_record_level) }
      root_record_id { nil }
      parent_id { nil }
    end
  end

  # JSON Models:
  # NOTE: these factories are used to generate example objects
  #       for the API docs - those docs currently rely on there
  #       being a factory named: "json_#{name_of_jsonmodel}",
  #       e.g. json_repository -> repository, json_term -> term
  #
  #       There can be additional factories per type which you can
  #       name whatever you want
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
    number {  generate(:phone_number) }
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
    note { [nil, generate(:alphanumstr)].sample }
  end

  factory :json_agent_corporate_entity, class: JSONModel(:agent_corporate_entity) do
    agent_type { 'agent_corporate_entity' }
    names { [build(:json_name_corporate_entity)] }
    agent_contacts { [build(:json_agent_contact)] }
    dates_of_existence { [build(:json_date, :label => 'existence')] }
  end

  factory :json_agent_family, class: JSONModel(:agent_family) do
    agent_type { 'agent_family' }
    names { [build(:json_name_family)] }
    dates_of_existence { [build(:json_date, :label => 'existence')] }
  end

  factory :json_agent_person, class: JSONModel(:agent_person) do
    agent_type { 'agent_person' }
    names { [build(:json_name_person)] }
    dates_of_existence { [build(:json_date, :label => 'existence')] }
  end

  factory :json_agent_software, class: JSONModel(:agent_software) do
    agent_type { 'agent_software' }
    names { [build(:json_name_software)] }
    dates_of_existence { [build(:json_date, :label => 'existence')] }
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
    xlink { Hash[%w(actuate arcrole href role show title type).map{|i| [i, i]}] }
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
    type_3 { sample(JSONModel(:sub_container).schema['properties']['type_3']) }
    indicator_3 { generate(:alphanumstr) }
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
    dates { generate(:alphanumstr) }
    qualifier { generate(:alphanumstr) }
    authority_id { generate(:url) }
    source { generate(:name_source) }
  end

  factory :json_name_family, class: JSONModel(:name_family) do
    rules { generate(:name_rule) }
    family_name { generate(:generic_name) }
    sort_name { generate(:sort_name) }
    sort_name_auto_generate { true }
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
    dates { generate(:alphanumstr) }
    qualifier { generate(:alphanumstr) }
    fuller_form { generate(:alphanumstr) }
    prefix { [nil, generate(:alphanumstr)].sample }
    title { [nil, generate(:alphanumstr)].sample }
    suffix { [nil, generate(:alphanumstr)].sample }
    rest_of_name { [nil, generate(:alphanumstr)].sample }
    authority_id { generate(:url) }
  end

  factory :json_name_software, class: JSONModel(:name_software) do
    rules { generate(:name_rule) }
    source { generate(:name_source) }
    software_name { generate(:generic_name) }
    sort_name { generate(:sort_name) }
    sort_name_auto_generate { true }
    dates { generate(:alphanumstr) }
    qualifier { generate(:alphanumstr) }
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
    finding_aid_description_rules { [nil, generate(:finding_aid_description_rules)].sample }
    ead_id { nil_or_whatever }
    finding_aid_date { generate(:alphanumstr) }
    finding_aid_series_statement { generate(:alphanumstr) }
    finding_aid_language {  [generate(:finding_aid_language)].sample  }
    finding_aid_script {  [generate(:finding_aid_script)].sample  }
    finding_aid_language_note { nil_or_whatever }
    finding_aid_note { generate(:alphanumstr) }
    ead_location { generate(:alphanumstr) }
    instances { [ build(:json_instance) ] }
    revision_statements {  [build(:json_revision_statement)]  }
  end

  factory :json_resource_nohtml, class: JSONModel(:resource) do
    title { "Resource #{generate(:generic_title)}" }
    id_0 { generate(:alphanumstr) }
    extents { [build(:json_extent)] }
    level { generate(:archival_record_level) }
    lang_materials { [build(:json_lang_material)] }
    dates { [build(:json_date), build(:json_date_single)] }
    finding_aid_description_rules { [nil, generate(:finding_aid_description_rules)].sample }
    ead_id { nil_or_whatever }
    finding_aid_date { generate(:alphanumstr) }
    finding_aid_series_statement { generate(:alphanumstr) }
    finding_aid_language {  [generate(:finding_aid_language)].sample  }
    finding_aid_script {  [generate(:finding_aid_script)].sample  }
    finding_aid_language_note { nil_or_whatever }
    finding_aid_note { generate(:alphanumstr) }
    ead_location { generate(:alphanumstr) }
    instances { [ build(:json_instance) ] }
    revision_statements {  [build(:json_revision_statement)]  }
  end

  factory :json_resource_blank_ead_location, class: JSONModel(:resource) do
    title { "Resource #{generate(:html_title)}" }
    id_0 { generate(:alphanumstr) }
    extents { [build(:json_extent)] }
    level { generate(:archival_record_level) }
    lang_materials { [build(:json_lang_material)] }
    dates { [build(:json_date), build(:json_date_single)] }
    finding_aid_description_rules { [nil, generate(:finding_aid_description_rules)].sample }
    ead_id { nil_or_whatever }
    finding_aid_date { generate(:alphanumstr) }
    finding_aid_series_statement { generate(:alphanumstr) }
    finding_aid_language {  [generate(:finding_aid_language)].sample  }
    finding_aid_script {  [generate(:finding_aid_script)].sample  }
    finding_aid_language_note { nil_or_whatever }
    finding_aid_note { generate(:alphanumstr) }
    ead_location { nil }
    instances { [ build(:json_instance) ] }
    revision_statements {  [build(:json_revision_statement)]  }
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
end
