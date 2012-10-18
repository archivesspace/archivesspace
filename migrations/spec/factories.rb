require 'factory_girl'



FactoryGirl.define do

  to_create{|instance| instance.save}

  sequence(:random_token) { |n| rand(36**8).to_s(36) }  
  
  factory :resource do
    title { generate(:random_token) }
    repo_id nil
    id_0 "AA"
    id_1 "BB"
  end
  
  factory :extent do
    number 20
    portion 'whole'
    extent_type 'reels'
    resource_id nil
    archival_object_id nil
  end
  
  factory :archival_object do
    title { generate(:random_token) }
    repo_id nil
    ref_id { generate(:random_token) }
    resource_id nil
    parent_id nil
  end
end

  
  