require 'factory_girl'

FactoryGirl.define do
  
  to_create{|instance| instance.save}
  
  factory :repo, class: Repository do
    repo_code 'ARCHIVESSPACE'
    description 'A new ArchivesSpace repository'
    after(:create) do |r|
      $repo_id = r.id
      $repo = JSONModel(:repository).uri_for(r.id)
      JSONModel::set_repository($repo_id)
    end
  end
  
  factory :user, class: User do
    username 'testusername'
    name 'A test user'
    source 'local'
  end
  
  factory :json_accession, class: JSONModel(:accession) do
    id_0 "1234"
    title "The accession title"
    content_description 'The accession description'
    condition_description 'The condition description'
    accession_date '2012-05-03'
  end

  factory :json_agent_person, class: JSONModel(:agent_person) do
    agent_type 'agent_person'
    names [{"rules" => "local",
            "primary_name" => "Magus Magoo",
            "sort_name" => "Magoo, Mr M",
            "direct_order" => "standard"}]
  end
  
  factory :json_archival_object, class: JSONModel(:archival_object) do
    ref_id '1234'
    level 'series'
    title 'The archival object title'
  end
  
  factory :json_container, class: JSONModel(:container) do
    type_1 'A Container'
    indicator_1 '555-1-2'
    barcode_1 '00011010010011'
  end
  
  factory :json_date, class: JSONModel(:date) do
    date_type 'single'
    label 'creation'
    # (the following two lines workaround the reserved word problem)
    self.begin '2012-05-14'
    self.end '2012-05-14'
  end
  
  # Add some sequences to auto-populate these
  factory :json_event, class: JSONModel(:event) do
    date nil
    event_type 'accession'
    linked_agents nil
    linked_records nil
  end   
  
  factory :json_group, class: JSONModel(:group) do
    group_code 'newgroup'
    description 'A test group'
  end
  
  factory :json_location, class: JSONModel(:location) do
    building '129 West 81st Street'
    floor '5'
    room '5A'
    barcode '010101100011'
  end
  
  factory :json_resource, class: JSONModel(:resource) do
    title 'a resource'
    id_0 'abc123'
    extents [{"portion" => "whole", "number" => "5 or so", "extent_type" => "reels"}]
  end
  
    
  
end