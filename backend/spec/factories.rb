require 'factory_bot'
require 'spec/lib/factory_bot_helpers'

# See common/spec/lib/factory_bot_helpers for shared JSONModel factories

FactoryBot.define do

  def JSONModel(key)
    JSONModel::JSONModel(key)
  end

  to_create {|instance| instance.save}

  sequence(:hh_mm) { t = Time.now; "#{t.hour}:#{t.min}" }
  sequence(:barcode) { 20.times.map { rand(2)}.join }
  sequence(:indicator) { (2+rand(3)).times.map { (2+rand(3)).times.map {rand(9)}.join }.join('-') }


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
                            :email => [nil, generate(:alphanumstr)].sample,
                            :email_signature => [nil, generate(:alphanumstr)].sample,
                            :json_schema_version => 1)
      end
    end

    factory :repo_telephone, class: Telephone do
      agent_contact_id { 1 }
      number_type { [nil, 'business', 'home', 'cell', 'fax'].sample }
      number { generate(:phone_number) }
      ext { [nil, generate(:alphanumstr)].sample }
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

    factory :agent_record_control, class: JSONModel(:agent_record_control) do
      maintenance_status { "new" }
      publication_status { "approved" }
      maintenance_agency { generate(:alphanumstr) }
      agency_name { generate(:alphanumstr) }
      maintenance_agency_note { generate(:alphanumstr) }
      language { generate(:language) }
      script { generate(:script) }
      language_note { generate(:alphanumstr) }
    end

    factory :agent_alternate_set, class: JSONModel(:agent_alternate_set) do
      file_version_xlink_actuate_attribute { "other"}
      file_version_xlink_show_attribute { "other" }
      set_component { generate(:alphanumstr) }
      descriptive_note { generate(:alphanumstr) }
      file_uri { generate(:alphanumstr) }
      xlink_title_attribute { generate(:alphanumstr) }
      xlink_role_attribute { generate(:alphanumstr) }
      xlink_arcrole_attribute { generate(:alphanumstr) }
      last_verified_date { generate(:yyyy_mm_dd) }
    end

    factory :agent_conventions_declaration, class: JSONModel(:agent_conventions_declaration) do
      file_version_xlink_actuate_attribute { "other"}
      file_version_xlink_show_attribute { "other" }
      name_rule { "aacr" }
      citation { generate(:alphanumstr) }
      descriptive_note { generate(:alphanumstr) }
      file_uri { generate(:alphanumstr) }
      xlink_title_attribute { generate(:alphanumstr) }
      xlink_role_attribute { generate(:alphanumstr) }
      xlink_arcrole_attribute { generate(:alphanumstr) }
      last_verified_date { generate(:yyyy_mm_dd) }
    end

    factory :agent_sources, class: JSONModel(:agent_sources) do
      file_version_xlink_actuate_attribute { "other"}
      file_version_xlink_show_attribute { "other" }
      descriptive_note { generate(:alphanumstr) }
      source_entry { generate(:alphanumstr) }
      file_uri { generate(:alphanumstr) }
      xlink_title_attribute { generate(:alphanumstr) }
      xlink_role_attribute { generate(:alphanumstr) }
      xlink_arcrole_attribute { generate(:alphanumstr) }
      last_verified_date { generate(:yyyy_mm_dd) }
    end

    factory :agent_other_agency_codes, class: JSONModel(:agent_other_agency_codes) do
      agency_code_type { "oclc"}
      maintenance_agency { generate(:alphanumstr) }
    end

    factory :agent_maintenance_history, class: JSONModel(:agent_maintenance_history) do
      maintenance_event_type { "created"}
      maintenance_agent_type { "human"}
      event_date { generate(:yyyy_mm_dd) }
      agent { generate(:alphanumstr) }
      descriptive_note { generate(:alphanumstr) }
    end

    factory :agent_record_identifier, class: JSONModel(:agent_record_identifier) do
      primary_identifier { true }
      record_identifier { generate(:alphanumstr) }
      source { "naf"}
      identifier_type { "loc"}
    end

    factory :resource do
      json_schema_version { 1 }
      title_id { [build(:title)] }
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

    factory :title do
      title { generate(:generic_title) }
    end

  end
end
