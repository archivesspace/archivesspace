require 'factory_girl'

def sample(enum)
  enum.reject {|i| i === 'other_unmapped' }.sample
end
  

FactoryGirl.define do
  
  to_create{|instance| instance.save}
  
  sequence(:repo_code) {|n| "ASPACE REPO #{n}"}
  sequence(:username) {|n| "username_#{n}"}
  
  sequence(:alphanumstr) { (0..4).map{ rand(3)==1?rand(10):(65 + rand(25)).chr }.join } 
  sequence(:generic_title) { |n| "Title: #{n}"}
  sequence(:generic_description) {|n| "Description: #{n}"}
  sequence(:generic_name) {|n| "Name Number #{n}"}
  sequence(:container_type) {|n| "Container Type #{n}"}
  sequence(:sort_name) { |n| "SORT #{('a'..'z').to_a[rand(26)]} - #{n}" }
  
  sequence(:phone_number) { (3..5).to_a[rand(3)].times.map { (3..5).to_a[rand(3)].times.map { rand(9) }.join }.join(' ') }
  sequence(:yyyy_mm_dd) { Time.at(rand * Time.now.to_i).to_s.sub(/\s.*/, '') }
  sequence(:hh_mm) { t = Time.now; "#{t.hour}:#{t.min}" }
  sequence(:number) { rand(100).to_s }
  sequence(:url) {|n| "http://www.example-#{n}.com"}
  sequence(:barcode) { 20.times.map { rand(2)}.join }
  sequence(:indicator) { (2+rand(3)).times.map { (2+rand(3)).times.map {rand(9)}.join }.join('-') }
  
  sequence(:name_rule) { sample(JSONModel(:abstract_name).schema['properties']['rules']['enum']) }
  sequence(:level) { %w(series subseries item)[rand(3)] }
  sequence(:term) { |n| "Term #{n}" }
  sequence(:term_type) { sample(JSONModel(:term).schema['properties']['term_type']['enum']) }

  sequence(:agent_role) { sample(JSONModel(:event).schema['properties']['linked_agents']['items']['properties']['role']['enum']) }
  sequence(:record_role) { sample(JSONModel(:event).schema['properties']['linked_records']['items']['properties']['role']['enum']) }
  
  sequence(:date_type) { sample(JSONModel(:date).schema['properties']['date_type']['enum']) }
  sequence(:date_lable) { sample(JSONModel(:date).schema['properties']['label']['enum']) }
  
  sequence(:event_type) { sample(JSONModel(:event).schema['properties']['event_type']['enum']) }
  sequence(:extent_type) { sample(JSONModel(:extent).schema['properties']['extent_type']['enum']) }
  sequence(:portion) { sample(JSONModel(:extent).schema['properties']['portion']['enum']) }
  sequence(:instance_type) { sample(JSONModel(:instance).schema['properties']['instance_type']['enum']) }
 
  sequence(:rights_type) { sample(JSONModel(:rights_statement).schema['properties']['rights_type']['enum']) }
  sequence(:ip_status) { sample(JSONModel(:rights_statement).schema['properties']['ip_status']['enum']) }
  sequence(:jurisdiction) { sample(JSONModel(:rights_statement).schema['properties']['jurisdiction']['enum']) }
  
  sequence(:container_location_status) { sample(JSONModel(:container_location).schema['properties']['status']['enum']) }
  sequence(:temporary_location_type) { sample(JSONModel(:location).schema['properties']['temporary']['enum']) }
  
  # AS Models
  
  factory :repo, class: Repository do
    repo_code { generate(:repo_code) }
    description { generate(:generic_description) }
    after(:create) do |r|
      $repo_id = r.id
      $repo = JSONModel(:repository).uri_for(r.id)
      JSONModel::set_repository($repo_id)
      RequestContext.put(:repo_id, $repo_id)
    end
  end
  
  factory :user, class: User do
    username { generate(:username) }
    name { generate(:generic_name) }
    source 'local'
  end
  
  factory :accession do
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
    title { generate(:generic_title) }
    id_0 { generate(:alphanumstr) }
    id_1 { generate(:alphanumstr) }
    level 'collection'
    language 'eng'
  end
  
  factory :extent do
    portion { generate(:portion) }
    number { generate(:number) }
    extent_type { generate(:extent_type) }
    resource_id nil
    archival_object_id nil
  end
  
  factory :archival_object do
    title { generate(:generic_title) }
    repo_id nil
    ref_id { generate(:alphanumstr) }
    level 'item'
    root_record_id nil
    parent_id nil
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
  
  factory :json_agent_contact, class: JSONModel(:agent_contact) do
    name { generate(:generic_name) }
    telephone { generate(:phone_number) }
  end

  factory :json_agent_corporate_entity, class: JSONModel(:agent_corporate_entity) do
    agent_type 'agent_corporate_entity'
    names { [build(:json_name_corporate_entity).to_hash] }
  end
  
  factory :json_agent_family, class: JSONModel(:agent_family) do
    agent_type 'agent_family'
    names { [build(:json_name_family).to_hash] }
  end
  
  factory :json_agent_person, class: JSONModel(:agent_person) do
    agent_type 'agent_person'
    names { [build(:json_name_person).to_hash] }
  end
  
  factory :json_agent_software, class: JSONModel(:agent_software) do
    agent_type 'agent_software'
    names { [build(:json_name_software).to_hash] }
  end
  
  factory :json_archival_object, class: JSONModel(:archival_object) do
    ref_id { generate(:alphanumstr) }
    level { generate(:level) }
    title { "Archival Object #{generate(:generic_title)}" }
  end

  factory :json_note_bibliography, class: JSONModel(:note_bibliography) do
    label { generate(:alphanumstr) }
    content { generate(:alphanumstr) }
    items { [generate(:alphanumstr)] }
  end

  factory :json_container, class: JSONModel(:container) do
    type_1 { generate(:container_type) }
    indicator_1 { generate(:indicator) }
    barcode_1 { generate(:barcode) }
  end
  
  factory :json_date, class: JSONModel(:date) do
    date_type { generate(:date_type) }
    label 'creation'
    self.begin { generate(:yyyy_mm_dd) }
    self.end { generate(:yyyy_mm_dd) }
    expression { generate(:alphanumstr) }
  end
  
  factory :json_deaccession, class: JSONModel(:deaccession) do
    scope { "whole" }
    description { generate(:generic_description) }
    date { build(:json_date).to_hash }
  end
  
  factory :json_digital_object, class: JSONModel(:digital_object) do
    title { "Digital Object #{generate(:generic_title)}" }
    digital_object_id { generate(:alphanumstr) }
    extents { [build(:json_extent).to_hash] }
  end
  
  factory :json_digital_object_component, class: JSONModel(:digital_object_component) do
    component_id { generate(:alphanumstr) }
    title { "Digital Object Component #{generate(:generic_title)}" }
  end

  factory :json_event, class: JSONModel(:event) do
    date { build(:json_date).to_hash }
    event_type { generate(:event_type) }
    linked_agents { [{'ref' => create(:json_agent_person).uri, 'role' => generate(:agent_role)}] }
    linked_records { [{'ref' => create(:json_accession).uri, 'role' => generate(:record_role)}] }
  end   
  
  factory :json_extent, class: JSONModel(:extent) do
    portion { generate(:portion) }
    number { generate(:number) }
    extent_type { generate(:extent_type) }
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
    container { build(:json_container).to_hash }
  end
  
  factory :json_location, class: JSONModel(:location) do
    building '129 West 81st Street'
    floor '5'
    room '5A'
    barcode { generate(:barcode) }
    temporary { generate(:temporary_location_type) }
  end
  
  factory :json_name_corporate_entity, class: JSONModel(:name_corporate_entity) do
    rules { generate(:name_rule) }
    primary_name { generate(:generic_name) }
    sort_name { generate(:sort_name) }
  end
  
  factory :json_name_family, class: JSONModel(:name_family) do
    rules { generate(:name_rule) }
    family_name { generate(:generic_name) }
    sort_name { generate(:sort_name) }
  end

  factory :json_name_person, class: JSONModel(:name_person) do
    rules { generate(:name_rule) }
    primary_name { generate(:generic_name) }
    sort_name { generate(:sort_name) }
    name_order 'direct'
  end
  
  factory :json_name_software, class: JSONModel(:name_software) do
    rules { generate(:name_rule) }
    software_name { generate(:generic_name) }
    sort_name { generate(:sort_name) }
  end
 
  factory :json_resource, class: JSONModel(:resource) do
    title { "Resource #{generate(:generic_title)}" }
    id_0 { generate(:alphanumstr) }
    extents { [build(:json_extent).to_hash] }
    level 'collection'
    language 'eng'
  end
  
  factory :json_repo, class: JSONModel(:repository) do
    repo_code { generate(:repo_code) }
    description { generate(:generic_description) }
  end
  
  # may need factories for each rights type
  factory :json_rights_statement, class: JSONModel(:rights_statement) do
    rights_type 'intellectual_property'
    ip_status { generate(:ip_status) }
    jurisdiction { generate(:jurisdiction) }
    active true
  end
  
  factory :json_subject, class: JSONModel(:subject) do
    terms { [build(:json_term).to_hash] }
    vocabulary { create(:json_vocab).uri }
    ref_id { generate(:url) }
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
    name { "Vocabulary #{generate(:generic_title)}" }
    ref_id { generate(:alphanumstr) }
  end


  factory :json_collection_management, class: JSONModel(:collection_management) do
    linked_records { [{'ref' => create(:json_accession).uri}] }
  end

end
