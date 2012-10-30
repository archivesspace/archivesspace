require 'factory_girl'

FactoryGirl.define do
  
  to_create{|instance| instance.save}
  
  sequence(:repo_code) {|n| "ASPACE REPO #{n}"}
  sequence(:username) {|n| "username_#{n}"}
  
  sequence(:alphanumstr) { |n| (0..4).map{ rand(3)==1?rand(10):(65 + rand(25)).chr }.join } 
  sequence(:generic_title) { |n| "Title: #{n}"}
  sequence(:generic_description) {|n| "Description: #{n}"}
  sequence(:yyyy_mm_dd) { Time.at(rand * Time.now.to_i).to_s.sub(/\s.*/, '') }
  sequence(:hh_mm) { t = Time.now; "#{t.hour}:#{t.min}" }
  sequence(:number) { |n| rand(100).to_s }
  sequence(:url) {|n| "http://www.example-#{n}.com"}
  
  sequence(:name_rule) { JSONModel(:abstract_name).schema['properties']['rules']['enum'].sample }
  sequence(:level) { |n| %w(series subseries otherlevel)[rand(3)] }
  sequence(:term) { |n| "Term #{n}" }
  sequence(:term_type) { JSONModel(:term).schema['properties']['term_type']['enum'].sample }

  sequence(:agent_role) { JSONModel(:event).schema['properties']['linked_agents']['items']['properties']['role']['enum'].sample }
  sequence(:record_role) { JSONModel(:event).schema['properties']['linked_records']['items']['properties']['role']['enum'].sample }
  
  sequence(:date_type) { JSONModel(:date).schema['properties']['date_type']['enum'].sample }
  
  sequence(:event_type) { JSONModel(:event).schema['properties']['event_type']['enum'].sample }
  sequence(:extent_type) { JSONModel(:extent).schema['properties']['extent_type']['enum'].sample }
  sequence(:portion) { JSONModel(:extent).schema['properties']['portion']['enum'].sample }
  sequence(:instance_type) { JSONModel(:instance).schema['properties']['instance_type']['enum'].sample }
 
  sequence(:rights_type) { JSONModel(:rights_statement).schema['properties']['rights_type']['enum'].sample }
  sequence(:ip_status) { JSONModel(:rights_statement).schema['properties']['ip_status']['enum'].sample }
  
  sequence(:container_location_status) { JSONModel(:container_location).schema['properties']['status']['enum'].sample } 
  
  
  factory :repo, class: Repository do
    repo_code { generate(:repo_code) }
    description { generate(:generic_description) }
    after(:create) do |r|
      $repo_id = r.id
      $repo = JSONModel(:repository).uri_for(r.id)
      JSONModel::set_repository($repo_id)
    end
  end
  
  factory :user, class: User do
    username { generate(:username) }
    name 'A test user'
    source 'local'
  end
  
  factory :json_accession, class: JSONModel(:accession) do
    id_0 { generate(:alphanumstr) }
    id_1 { generate(:alphanumstr) }
    id_2 { generate(:alphanumstr) }
    id_3 { generate(:alphanumstr) }
    title { "Accession " + generate(:generic_title) }
    content_description 'The accession description'
    condition_description 'The condition description'
    accession_date { generate(:yyyy_mm_dd) }
  end
  
  factory :json_agent_contact, class: JSONModel(:agent_contact) do
    name 'Contact name'
    telephone '0011 1234 1234'
  end

  factory :json_agent_corporate_entity, class: JSONModel(:agent_corporate_entity) do
    agent_type 'agent_corporate_entity'
    names { [build(:json_name_corporate_entity).to_hash] }
  end
  
  factory :json_agent_family, class: JSONModel(:agent_family) do
    agent_type "agent_family"
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
  
  factory :json_container, class: JSONModel(:container) do
    type_1 'A Container'
    indicator_1 '555-1-2'
    barcode_1 '00011010010011'
  end
  
  factory :json_container_location, class: JSONModel(:container_location) do
    status { generate(:container_location_status) }
    start_date { generate(:yyyy_mm_dd) }
    end_date { generate(:yyyy_mm_dd) }
  end
  
  factory :json_date, class: JSONModel(:date) do
    date_type { generate(:date_type) }
    label 'creation'
    self.begin { generate(:yyyy_mm_dd) }
    self.end { generate(:yyyy_mm_dd) }
    expression { generate(:alphanumstr) }
  end
  
  factory :json_digital_object, class: JSONModel(:digital_object) do
    title { "Digital Object #{generate(:generic_title)}" }
    digital_object_id { generate(:alphanumstr) }
    extents { [build(:json_extent).to_hash] }
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
    barcode '010101100011'
  end
  
  factory :json_name_corporate_entity, class: JSONModel(:name_corporate_entity) do
    rules { generate(:name_rule) }
    primary_name 'Magus Magoo Inc'
    sort_name 'Magus Magoo Inc'
  end
  
  factory :json_name_family, class: JSONModel(:name_family) do
    rules { generate(:name_rule) }
    family_name 'Magoo Family'
    sort_name 'Family Magoo'
  end

  factory :json_name_person, class: JSONModel(:name_person) do
    rules { generate(:name_rule) }
    primary_name 'Magus Magoo'
    sort_name 'Magoo, Mr M'
    direct_order 'standard'
  end
  
  factory :json_name_software, class: JSONModel(:name_software) do
    rules { generate(:name_rule) }
    software_name 'Magus Magoo Freeware'
    sort_name 'Magoo, Mr M'
  end
 
  factory :json_resource, class: JSONModel(:resource) do
    title { "Resource #{generate(:generic_title)}" }
    id_0 { generate(:alphanumstr) }
    extents { [build(:json_extent).to_hash] }
  end
  
  factory :json_rights_statement, class: JSONModel(:rights_statement) do
    identifier { generate(:alphanumstr) }
    rights_type 'intellectual_property'
    ip_status { generate(:ip_status) }
    jurisdiction { generate(:alphanumstr) }
    active true
  end
  
  factory :json_subject, class: JSONModel(:subject) do
    terms { [build(:json_term)] }
    vocabulary { create(:json_vocab).uri }
  end
  
  factory :json_term, class: JSONModel(:term) do
    term { generate(:term) }
    term_type { generate(:term_type) }
    vocabulary { create(:json_vocab).uri }
  end
  
  factory :json_vocab, class: JSONModel(:vocabulary) do
    name { "Vocabulary #{generate(:generic_title)}" }
    ref_id { generate(:alphanumstr) }
  end
    
  
end