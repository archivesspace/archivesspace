require 'factory_bot'
require 'spec/lib/factory_bot_helpers'

FactoryBot.define do

  def JSONModel(key)
    JSONModel::JSONModel(key)
  end

  to_create{|instance| instance.save}

  sequence(:generic_title) { |n| "Title: #{n}"}
  sequence(:html_title) { |n| "Title: <emph render='italic'>#{n}</emph>"}
  sequence(:container_type) {|n| 'box'}
  sequence(:yyyy_mm_dd) { Time.at(rand * Time.now.to_i).to_s.sub(/\s.*/, '') }
  sequence(:level) { %w(series subseries item)[rand(3)] }

  factory :json_archival_object, class: JSONModel(:archival_object) do
    ref_id { generate(:alphanumstr) }
    level { generate(:level) }
    title { "Archival Object #{generate(:generic_title)}" }
    resource { {'ref' => create(:json_resource).uri} }
  end

  factory :json_top_container, class: JSONModel(:top_container) do
    indicator { generate(:alphanumstr) }
    type { generate(:container_type) }
    barcode { SecureRandom.hex }
    ils_holding_id { generate(:alphanumstr) }
    ils_item_id { generate(:alphanumstr) }
    exported_to_ils { Time.now.iso8601 }
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

  factory :json_extent, class: JSONModel(:extent) do
    portion { generate(:portion) }
    number { generate(:number) }
    extent_type { generate(:extent_type) }
    dimensions { generate(:alphanumstr) }
    physical_details { generate(:alphanumstr) }
  end

  factory :json_instance, class: JSONModel(:instance) do
    instance_type { generate(:instance_type) }
    sub_container { build(:json_sub_container) }
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

  factory :json_revision_statement, class: JSONModel(:revision_statement) do
    date { generate(:alphanumstr) }
    description { generate(:alphanumstr) }
  end
end
