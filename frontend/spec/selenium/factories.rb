# frozen_string_literal: true

require 'jsonmodel'
require 'factory_bot'
require 'spec/lib/factory_bot_helpers'

require_relative '../../../common/selenium/backend_client_mixin'

include BackendClientMethods
include JSONModel

module SeleniumFactories
  def self.init
    @@inited ||= false

    return true if @@inited

    JSONModel.init(client_mode: true,
                   url: AppConfig[:backend_url],
                   priority: :high)

    FactoryBot.define do
      to_create do |instance|
        try_again = true
        begin
          instance.save
        rescue Exception => e
          if e.class.name == 'AccessDeniedException' && try_again
            try_again = false
            url = URI.parse(AppConfig[:backend_url] + '/users/admin/login')
            request = Net::HTTP::Post.new(url.request_uri)
            request.set_form_data('expiring' => 'false',
                                  'password' => 'admin')
            response = do_http_request(url, request)

            if response.code == '200'
              auth = ASUtils.json_parse(response.body)

              JSONModel::HTTP.current_backend_session = auth['session']
              retry
            else
              raise "Authentication to backend failed: #{response.body}"
            end
          else
            raise e
          end
        end
      end

      sequence(:username) { |n| "testuser_#{n}_#{Time.now.to_i}" }
      sequence(:user_name) { |n| "Test User #{n}_#{Time.now.to_i}" }

      sequence(:repo_code) { |n| "testrepo_#{n}_#{Time.now.to_i}" }
      sequence(:repo_name) { |n| "Test Repo #{n}" }
      sequence(:accession_id) { |n| n.to_s }

      sequence(:ref_id) { |n| "aspace_#{n}" }
      sequence(:id_0) { |n| "#{Time.now.to_i}_#{n}" }

      sequence(:accession_title) { |n| "Accession #{n}" }
      sequence(:resource_title) { |n| "Resource #{n}" }
      sequence(:archival_object_title) { |n| "Archival Object #{n}" }
      sequence(:digital_object_title) { |n| "Digital Object #{n}" }
      sequence(:digital_object_component_title) { |n| "Digital Object #{n}" }
      sequence(:classification_title) { |n| "Classification #{n}" }
      sequence(:classification_term_title) { |n| "Classification Term #{n}" }

      sequence(:rde_template_name) { |n| "RDE Template #{n}_#{Time.now.to_i}" }
      sequence(:four_part_id) { Digest::MD5.hexdigest("#{Time.now}#{SecureRandom.uuid}#{$$}").scan(/.{6}/)[0...1] }

      sequence(:top_container_indicator) { |n| "Container #{n}" }
      sequence(:building) { |n| "Maggie's #{n}th Farm_#{Time.now.to_i}" }

      sequence(:yyyy_mm_dd) { Time.at(rand * Time.now.to_i).to_s.sub(/\s.*/, '') }
      sequence(:phone_number) { (3..5).to_a[rand(3)].times.map { (3..5).to_a[rand(3)].times.map { rand(9) }.join }.join(' ') }
      sequence(:hh_mm) { t = Time.now; "#{t.hour}:#{t.min}" }

      factory :repo, class: JSONModel(:repository) do
        repo_code { generate :repo_code }
        name { generate :repo_name }
        org_code { '123' }
        image_url { 'http://foo.com/bar' }
        url { 'http://foo.com' }
      end

      factory :user, class: JSONModel(:user) do
        username { generate :username }
        name { generate :user_name }
      end

      factory :accession, class: JSONModel(:accession) do
        title { generate(:accession_title) }
        id_0 { generate(:accession_id) }
        id_1 { generate(:accession_id) }
        id_2 { generate(:accession_id) }
        id_3 { generate(:accession_id) }
        content_description { '9 guinea pigs' }
        condition_description { 'furious' }
        accession_date { '1990-01-01' }
      end

      factory :collection_management, class: JSONModel(:collection_management) do
        processing_total_extent { '10' }
        processing_status { 'completed' }
        processing_total_extent_type { 'cassettes' }
        processing_hours_per_foot_estimate { '80' }
      end

      factory :resource, class: JSONModel(:resource) do
        title { generate :resource_title }
        id_0 { generate(:alphanumstr) }
        id_1 { generate(:alphanumstr) }
        extents { [build(:extent)] }
        dates { [build(:date)] }
        level { 'collection' }
        finding_aid_language { 'eng' }
        finding_aid_script { 'Latn' }
        lang_materials { [build(:json_lang_material)] }
      end

      factory :archival_object, class: JSONModel(:archival_object) do
        title { generate(:archival_object_title) }
        ref_id { generate(:ref_id) }
        level { 'item' }
      end

      factory :digital_object, class: JSONModel(:digital_object) do
        title { generate :digital_object_title }
        lang_materials { [build(:json_lang_material)] }
        digital_object_id { generate(:ref_id) }
        extents { [build(:extent)] }
        file_versions { [build(:file_version)] }
        dates { few_or_none(:date) }
      end

      factory :digital_object_component, class: JSONModel(:digital_object_component) do
        component_id { generate(:alphanumstr) }
        title { generate :digital_object_component_title }
      end

      factory :instance_digital, class: JSONModel(:instance) do
        instance_type { 'digital_object' }
        digital_object { { 'ref' => create(:digital_object).uri } }
      end

      factory :file_version, class: JSONModel(:file_version) do
        file_uri { 'http://example.com/1' }
        use_statement { generate(:use_statement) }
        xlink_actuate_attribute { generate(:xlink_actuate_attribute) }
        xlink_show_attribute { generate(:xlink_show_attribute) }
        file_format_name { generate(:file_format_name) }
        file_format_version { generate(:alphanumstr) }
        file_size_bytes { generate(:number).to_i }
        checksum { generate(:alphanumstr) }
        checksum_method { generate(:checksum_method) }
      end

      factory :extent, class: JSONModel(:extent) do
        portion { 'whole' }
        number { '1' }
        extent_type { 'gigabytes' }
      end

      factory :date, class: JSONModel(:date) do
        date_type { 'inclusive' }
        label { 'creation' }
        self.begin { '1900-01-01' }
        self.end { '1999-12-31' }
        expression { '1900s' }
      end

      factory :json_lang_material, class: JSONModel(:lang_material) do
        language_and_script { build(:json_language_and_script) }
      end

      factory :json_language_and_script, class: JSONModel(:language_and_script) do
        language { generate(:language) }
        script { generate(:script) }
      end

      factory :rde_template, class: JSONModel(:rde_template) do
        record_type { 'archival_object' }
        name { generate(:rde_template_name) }
        order { [] }
        visible { %w[colLevel colOtherLevel colTitle colCompId colLang colExpr colDType colDBegin colDEnd colIType colCType1 colCInd1 colCBarc1 colCType2 colCInd2 colCType3 colCInd3 colNType1 colNCont1 colNType2 colNCont2 colNType3 colNCont3] }
        defaults do
          {
            'colTitle' => 'DEFAULT TITLE',
            'colLevel' => 'item'
          }
        end
      end

      factory :name_person, class: JSONModel(:name_person) do
        rules { generate(:name_rule) }
        source { generate(:name_source) }
        primary_name { generate(:alphanumstr) }
        rest_of_name { generate(:alphanumstr) }
        sort_name { generate(:sort_name) }
        name_order { %w[direct inverted].sample }
        number { generate(:alphanumstr) }
        sort_name_auto_generate { true }
        dates { generate(:alphanumstr) }
        qualifier { generate(:alphanumstr) }
      end

      factory :agent_contact, class: JSONModel(:agent_contact) do
        name { generate(:generic_name) }
      end

      factory :agent_person, class: JSONModel(:agent_person) do
        agent_type { 'agent_person' }
        names { [build(:name_person)] }
        dates_of_existence { [build(:json_structured_date_label)] }
        agent_contacts { [build(:json_agent_contact)] }
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

      factory :agent_corporate_entity, class: JSONModel(:agent_corporate_entity) do
        agent_type { 'agent_corporate_entity' }
        names { [build(:json_name_corporate_entity)] }
        agent_contacts { [build(:json_agent_contact)] }
        dates_of_existence { [build(:json_structured_date_label)] }
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
                 build(:json_note_general_context)]}
      end

      factory :json_structured_date_label, class: JSONModel(:structured_date_label) do
        date_type_structured { "single" }
        date_label { 'existence' }
        structured_date_single { build(:json_structured_date_single) }
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

      factory :json_agent_place, class: JSONModel(:agent_place) do
        place_role { "place_of_birth" }
        dates { [build(:json_structured_date_label)] }
        notes { [build(:json_note_text)] }
        subjects { [{'ref' => create(:json_subject).uri}] }
      end

      factory :json_agent_occupation, class: JSONModel(:agent_occupation) do
        dates { [build(:json_structured_date_label)] }
        notes { [build(:json_note_text)] }
        subjects { [{'ref' => create(:json_subject).uri}] }
        places { [{'ref' => create(:json_subject).uri}] }
      end

      factory :json_agent_function, class: JSONModel(:agent_function) do
        dates { [build(:json_structured_date_label)] }
        notes { [build(:json_note_text)] }
        subjects { [{'ref' => create(:json_subject).uri}] }
        places { [{'ref' => create(:json_subject).uri}] }
      end

      factory :json_agent_topic, class: JSONModel(:agent_topic) do
        dates { [build(:json_structured_date_label)] }
        notes { [build(:json_note_text)] }
        subjects { [{'ref' => create(:json_subject).uri}] }
        places { [{'ref' => create(:json_subject).uri}] }
      end

      factory :json_agent_resource, class: JSONModel(:agent_resource) do
        dates { [build(:json_structured_date_label)] }
        places { [{'ref' => create(:json_subject).uri}] }
        file_version_xlink_actuate_attribute { "other"}
        file_version_xlink_show_attribute { "other" }
        xlink_title_attribute { generate(:alphanumstr) }
        xlink_role_attribute { generate(:alphanumstr) }
        xlink_arcrole_attribute { generate(:alphanumstr) }
        linked_resource { generate(:alphanumstr) }
        linked_resource_description { generate(:alphanumstr) }
        file_uri { generate(:alphanumstr) }
        linked_agent_role { "creator" }
      end

      # NOTE: using this factory will fail unless values are added manually to the gender enum list. See agent_spec_helper.rb#add_gender_values
      factory :json_agent_gender, class: JSONModel(:agent_gender) do
        dates { [build(:json_structured_date_label)] }
        gender { "not_specified" }
        notes { [build(:json_note_text)] }
      end

      factory :json_agent_identifier, class: JSONModel(:agent_identifier) do
        entity_identifier { generate(:alphanumstr) }
        identifier_type { "loc"}
      end

      factory :json_used_language, class: JSONModel(:used_language) do
        language { generate(:language) }
        script { generate(:script) }
        notes { [build(:json_note_text)] }
      end

      factory :json_note_text, class: JSONModel(:note_text) do
        content { generate(:alphanumstr) }
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

      factory :json_vocabulary, class: JSONModel(:vocabulary) do
        name { generate(:vocab_name) }
        ref_id { generate(:vocab_refid) }
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
      end

      factory :json_note_bioghist, class: JSONModel(:note_bioghist) do
        label { generate(:alphanumstr) }
        subnotes { [ build(:json_note_text), build(:json_note_text) ] }
      end

      factory :json_note_general_context, class: JSONModel(:note_general_context) do
        label { generate(:alphanumstr) }
        subnotes { [ build(:json_note_text) ] }
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

      factory :json_telephone, class: JSONModel(:telephone) do
        number_type { [nil, 'business', 'home', 'cell', 'fax'].sample }
        number { generate(:phone_number) }
        ext { [nil, generate(:alphanumstr)].sample }
      end

      factory :subject, class: JSONModel(:subject) do
        terms { [build(:term)] }
        vocabulary { create(:vocab).uri }
        authority_id { generate(:url) }
        scope_note { generate(:alphanumstr) }
        source { generate(:subject_source) }
      end

      factory :term, class: JSONModel(:term) do
        term { generate(:term) }
        term_type { generate(:term_type) }
        vocabulary { create(:vocab).uri }
      end

      factory :top_container, class: JSONModel(:top_container) do
        indicator { generate(:top_container_indicator) }
      end

      factory :container_location, class: JSONModel(:container_location) do
        status { 'current' }
        start_date { '2015-01-01' }
      end

      factory :location, class: JSONModel(:location) do
        building { generate(:building) }
        barcode { '8675309' }
      end

      factory :vocab, class: JSONModel(:vocabulary) do
        name { generate(:vocab_name) }
        ref_id { generate(:vocab_refid) }
      end

      factory :classification, class: JSONModel(:classification) do
        identifier { generate(:alphanumstr) }
        title { generate(:classification_title) }
        description { generate(:alphanumstr) }
      end

      factory :classification_term, class: JSONModel(:classification_term) do
        identifier { generate(:alphanumstr) }
        title { generate(:classification_term_title) }
        description { generate(:alphanumstr) }
      end

      factory :container_profile, class: JSONModel(:container_profile) do
        name { generate(:alphanumstr) }
        extent_dimension { 'width' }
        dimension_units { 'inches' }
        width { '10' }
        height { '10' }
        depth { '10' }
      end

      factory :location_profile, class: JSONModel(:location_profile) do
        name { generate(:alphanumstr) }
        dimension_units { 'inches' }
        width { '100' }
        height { '20' }
        depth { '20' }
      end
    end

    @@inited = true
  end
end
