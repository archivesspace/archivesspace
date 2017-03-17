require 'factory_girl'
require 'spec/lib/factory_girl_helpers'

FactoryGirl.define do

  def JSONModel(key)
    JSONModel::JSONModel(key)
  end

  to_create{|instance| instance.save}

  sequence(:repo_code) {|n| "ASPACE REPO #{n} -- #{rand(1000000)}"}
  sequence(:username) {|n| "username_#{n}"}

  sequence(:good_markup) { "<p>I'm</p><p>GOOD</p><p>#{ FactoryGirl.generate(:alphanumstr)}</p>" }
  sequence(:whack_markup) { "I'm <p><br/>WACK " + FactoryGirl.generate(:alphanumstr) }
  sequence(:wild_markup) { "<p> I AM \n WILD \n ! \n ! " + FactoryGirl.generate(:alphanumstr) + "</p>" }
  sequence(:string) { FactoryGirl.generate(:alphanumstr) }
  sequence(:generic_title) { |n| "Title: #{n}"}
  sequence(:html_title) { |n| "Title: <emph render='italic'>#{n}</emph>"}
  sequence(:generic_description) {|n| "Description: #{n}"}
  sequence(:container_type) {|n| sample(JSONModel(:container).schema['properties']['type_1'])}
  sequence(:archival_object_language) {|n| sample(JSONModel(:abstract_archival_object).schema['properties']['language']) }

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
      agent_record_type :agent_person
      agent_record_id {JSONModel(:agent_person).id_for(create(:json_agent_person).uri)}
      source 'local'
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
      language { generate(:language) }

    end

    factory :extent do
      json_schema_version { 1 }
      portion { generate(:portion) }
      number { generate(:number) }
      extent_type { generate(:extent_type) }
      resource_id nil
      archival_object_id nil
    end

    factory :archival_object do
      json_schema_version { 1 }
      title { generate(:generic_title) }
      repo_id nil
      ref_id { generate(:alphanumstr) }
      level { generate(:archival_record_level) }
      root_record_id nil
      parent_id nil
    end
  end
  # JSON Models:

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
    agent_type 'agent_corporate_entity'
    names { [build(:json_name_corporate_entity)] }
    agent_contacts { [build(:json_agent_contact)] }
    dates_of_existence { [build(:json_date, :label => 'existence')] }
  end

  factory :json_agent_family, class: JSONModel(:agent_family) do
    agent_type 'agent_family'
    names { [build(:json_name_family)] }
    dates_of_existence { [build(:json_date, :label => 'existence')] }
  end

  factory :json_agent_person, class: JSONModel(:agent_person) do
    agent_type 'agent_person'
    names { [build(:json_name_person)] }
    dates_of_existence { [build(:json_date, :label => 'existence')] }
  end

  factory :json_agent_software, class: JSONModel(:agent_software) do
    agent_type 'agent_software'
    names { [build(:json_name_software)] }
    dates_of_existence { [build(:json_date, :label => 'existence')] }
  end

  factory :json_archival_object, class: JSONModel(:archival_object) do
    ref_id { generate(:alphanumstr) }
    level { generate(:level) }
    title { "Archival Object #{generate(:generic_title)}" }
    resource { {'ref' => create(:json_resource).uri} }
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
    xlink Hash[%w(actuate arcrole href role show title type).map{|i| [i, i]}]
  end

  factory :json_note_chronology, class: JSONModel(:note_chronology) do
    title { nil_or_whatever }
    items { (0..rand(3)).map { generate(:chronology_item) } }
  end

  factory :json_note_outline_level, class: JSONModel(:note_outline_level) do
    items { [ generate(:alphanumstr) ] }
  end

  factory :json_container, class: JSONModel(:container) do
    type_1 { generate(:container_type) }
    indicator_1 { generate(:indicator) }
    barcode_1 { generate(:barcode) }
    container_extent { generate (:number) }
    container_extent_type { sample(JSONModel(:container).schema['properties']['container_extent_type']) }
  end

  factory :json_top_container, class: JSONModel(:top_container) do
    indicator { generate(:alphanumstr) }
    type { generate(:container_type) }
    barcode { generate(:alphanumstr)[0..4] }
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
    type_2 { sample(JSONModel(:sub_container).schema['properties']['type_2']) }
    indicator_2 { generate(:alphanumstr) }
    type_3 { sample(JSONModel(:sub_container).schema['properties']['type_3']) }
    indicator_3 { generate(:alphanumstr) }
  end


  factory :json_date, class: JSONModel(:date) do
    date_type { generate(:date_type) }
    label 'creation'
    self.begin { generate(:yyyy_mm_dd) }
    self.end { self.begin }
    expression { generate(:alphanumstr) }
  end

  factory :json_deaccession, class: JSONModel(:deaccession) do
    scope { "whole" }
    description { generate(:generic_description) }
    date { build(:json_date) }
  end

  factory :json_digital_object, class: JSONModel(:digital_object) do
    title { "Digital Object #{generate(:generic_title)}" }
    language { generate(:archival_object_language) }
    digital_object_id { generate(:alphanumstr) }
    extents { [build(:json_extent)] }
    file_versions { few_or_none(:json_file_version) }
    dates { few_or_none(:json_date) }
  end

  factory :json_digital_object_component, class: JSONModel(:digital_object_component) do
    component_id { generate(:alphanumstr) }
    title { "Digital Object Component #{generate(:generic_title)}" }
    digital_object { {'ref' => create(:json_digital_object).uri} }
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
    container { build(:json_container) }
  end

  factory :json_instance_digital, class: JSONModel(:instance) do
    instance_type 'digital_object'
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
    sort_name_auto_generate true
    dates { generate(:alphanumstr) }
    qualifier { generate(:alphanumstr) }
    authority_id { generate(:url) }
    source { generate(:name_source) }
  end

  factory :json_name_family, class: JSONModel(:name_family) do
    rules { generate(:name_rule) }
    family_name { generate(:generic_name) }
    sort_name { generate(:sort_name) }
    sort_name_auto_generate true
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
    sort_name_auto_generate true
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
    software_name { generate(:generic_name) }
    sort_name { generate(:sort_name) }
    sort_name_auto_generate true
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

  factory :json_resource, class: JSONModel(:resource) do
    title { "Resource #{generate(:html_title)}" }
    id_0 { generate(:alphanumstr) }
    extents { [build(:json_extent)] }
    level { generate(:archival_record_level) }
    language { generate(:language) }
    dates { [build(:json_date)] }
    finding_aid_description_rules { [nil, generate(:finding_aid_description_rules)].sample }
    ead_id { nil_or_whatever }
    finding_aid_date { generate(:alphanumstr) }
    finding_aid_language { nil_or_whatever }
    ead_location { generate(:alphanumstr) }
    instances { [build(:json_instance), build(:json_instance)] }
    revision_statements {  [build(:json_revision_statement)]  }
  end

  factory :json_revision_statement, class: JSONModel(:revision_statement) do
    date { generate(:alphanumstr) }
    description { generate(:alphanumstr) }
  end

  factory :json_repo, class: JSONModel(:repository) do
    repo_code { generate(:repo_code) }
    name { generate(:generic_description) }
    org_code { generate(:alphanumstr) }
    image_url { generate(:url) }
    url { generate(:url) }
  end


  factory :json_repo_with_agent, class: JSONModel(:repository_with_agent) do
    repository { build(:json_repo) }
    agent_representation { build(:json_agent_corporate_entity) }
  end

  # may need factories for each rights type
  factory :json_rights_statement, class: JSONModel(:rights_statement) do
    rights_type 'intellectual_property'
    ip_status { generate(:ip_status) }
    jurisdiction { generate(:jurisdiction) }
    active true
  end

  factory :json_subject, class: JSONModel(:subject) do
    terms { [build(:json_term)] }
    vocabulary { create(:json_vocab).uri }
    authority_id { generate(:url) }
    scope_note { generate(:alphanumstr) }
    source { generate(:subject_source) }
  end

  factory :json_term, class: JSONModel(:term) do
    term { generate(:term) }
    term_type { generate(:term_type) }
    vocabulary { create(:json_vocab).uri }
  end

  factory :json_user, class: JSONModel(:user) do
    username { generate(:username) }
    name { generate(:generic_name) }
  end

  factory :json_vocab, class: JSONModel(:vocabulary) do
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

  factory :json_print_to_pdf_job, class: JSONModel(:print_to_pdf_job) do
    source  { create(:json_resource).uri }
  end

  factory :json_find_and_replace_job, class: JSONModel(:find_and_replace_job) do
    find "/foo/"
    replace "bar"
    record_type "extent"
    property "container_summary"
    base_record_uri "repositories/2/resources/1"
  end

  factory :json_preference, class: JSONModel(:preference) do
    defaults { build(:json_defaults) }
  end

  factory :json_defaults, class: JSONModel(:defaults) do
    show_suppressed { false }
    publish { false }
  end
end
