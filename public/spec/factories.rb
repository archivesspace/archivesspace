FactoryGirl.define do

  sequence(:string) {|n| "string #{n}" } 

  factory :digital_object, class: JSONModel::JSONModel(:digital_object) do
    title { "Digital Object #{generate(:generic_title)}" }
    language { 'eng' }
    digital_object_id { generate(:string) }
    extents { [build(:extent)] }
    file_versions { [build(:file_version)] }
    dates { [build(:date)] }
  end

  factory :file_version, class: JSONModel::JSONModel(:file_version) do
    file_uri { generate(:string) }
    use_statement { generate(:string) }
    xlink_actuate_attribute { generate(:string) }
    xlink_show_attribute { generate(:string) }
    file_format_name { generate(:string) }
    file_format_version { generate(:string) }
    file_size_bytes { rand(10) }
    checksum { generate(:string) }
    checksum_method { 'md5' }
  end

  factory :extent, class: JSONModel::JSONModel(:extent) do
    portion { 'whole' }
    number { 10 }
    extent_type { 'linear_feet' }
  end

  factory :date, class: JSONModel::JSONModel(:date) do
    date_type { 'single' }
    label 'creation'
    self.begin { '1900' }
    self.end { '2000' }
    expression { generate(:string) }
  end
end
