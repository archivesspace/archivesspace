require 'jsonmodel'
require 'factory_bot'
require 'spec/lib/factory_bot_helpers'

require_relative '../../common/selenium/backend_client_mixin'

include BackendClientMethods
include JSONModel

module AspaceFactories

  def self.login_backend
    url = URI.parse(AppConfig[:backend_url] + "/users/admin/login")
    request = Net::HTTP::Post.new(url.request_uri)
    request.set_form_data("expiring" => "false",
                          "password" => "admin")
    response = do_http_request(url, request)

    if response.code == '200'
      auth = ASUtils.json_parse(response.body)
      JSONModel::HTTP.current_backend_session = auth['session']
    else
      raise "Authentication to backend failed: #{response.body}"
    end
  end

  def self.init
    @@inited ||= false

    if @@inited
      return true
    end

    # This actually needs to happen regardless of whether a factory is used, as some test suites skip fixture creation,
    # yet still require a backend session because they at least run the indexer.
    puts "ASpaceFactories: logging in to backend..."
    login_backend

    FactoryBot.define do

      to_create {|instance|
        try_again = true
        begin
          instance.save
        rescue Exception => e
          if e.class.name == "AccessDeniedException" && try_again
            puts "FactoryBot: backend access denied while saving instance; will attempt login and try again"
            try_again = false
            login_backend
            retry
          else
            raise e
          end
        end
      }

      sequence(:user_name) {|n| "Test User #{n}_#{Time.now.to_i}"}

      sequence(:repo_name) {|n| "Test Repo #{n}"}
      sequence(:accession_id) {|n| "#{n}" }

      sequence(:ref_id) {|n| "aspace_#{n}"}
      sequence(:id_0) {|n| "#{Time.now.to_i}_#{n}"}

      sequence(:accession_title) { |n| "Accession #{n}" }
      sequence(:resource_title) { |n| "Resource #{n}" }
      sequence(:archival_object_title) {|n| "Archival Object #{n}"}
      sequence(:digital_object_title) {|n| "Digital Object #{n}"}
      sequence(:digital_object_component_title) {|n| "Digital Object #{n}"}
      sequence(:classification_title) {|n| "Classification #{n}"}
      sequence(:classification_term_title) {|n| "Classification Term #{n}"}

      sequence(:top_container_indicator) {|n| "Container #{n}"}
      sequence(:building) {|n| "Maggie's #{n}th Farm_#{Time.now.to_i}" }

      factory :repo, class: JSONModel(:repository) do
        repo_code { generate :repo_code }
        name { generate :repo_name }
        publish { true }
        org_code { "123" }
        image_url { "http://foo.com/bar" }
        url { "http://foo.com" }
      end

      factory :user, class: JSONModel(:user) do
        username { generate :username }
        name { generate :user_name}
      end

      factory :accession, class: JSONModel(:accession) do
        title { generate(:accession_title) }
        id_0 { generate(:accession_id) }
        id_1 { generate(:accession_id) }
        id_2 { generate(:accession_id) }
        id_3 { generate(:accession_id) }
        publish { true }
        content_description { "9 guinea pigs" }
        condition_description { "furious" }
        accession_date { "1990-01-01" }
      end

      factory :accession_parts_relationship, class: JSONModel(:accession_parts_relationship) do
        ref { create(:accession).uri }
        relator_type { "part" }
        relator { "has_part" }
      end

      factory :accession_with_deaccession, class: JSONModel(:accession) do
        title { generate(:accession_title) }
        id_0 { generate(:accession_id) }
        id_1 { generate(:accession_id) }
        id_2 { generate(:accession_id) }
        id_3 { generate(:accession_id) }
        publish { true }
        content_description { generate(:generic_description) }
        condition_description { generate(:generic_description) }
        accession_date { generate(:yyyy_mm_dd) }
        deaccessions { [build(:json_deaccession)] }
      end

      factory :collection_management, class: JSONModel(:collection_management) do
        processing_total_extent { "10" }
        processing_status { "completed" }
        processing_total_extent_type { "cassettes" }
        processing_hours_per_foot_estimate { "80" }
      end


      factory :resource, class: JSONModel(:resource) do
        title { generate :resource_title }
        id_0 { generate :id_0 }
        extents { [build(:extent)] }
        dates { [build(:date)] }
        level { "collection" }
        lang_materials { [build(:lang_material)] }
        finding_aid_language { [generate(:finding_aid_language)].sample }
        finding_aid_script { [generate(:finding_aid_script)].sample }
        finding_aid_language_note { nil_or_whatever }
        instances { [] }
      end

      factory :resource_with_scope, class: JSONModel(:resource) do
        title { generate :resource_title }
        id_0 { generate :id_0 }
        extents { [build(:extent)] }
        dates { [build(:date)] }
        level { "collection" }
        lang_materials { [build(:lang_material)] }
        finding_aid_language { [generate(:finding_aid_language)].sample }
        finding_aid_script { [generate(:finding_aid_script)].sample }
        notes { [build(:json_note_multipart)] }
      end

      factory :archival_object, class: JSONModel(:archival_object) do
        title { generate(:archival_object_title) }
        ref_id { generate(:ref_id) }
        level { "item" }
      end


      factory :digital_object, class: JSONModel(:digital_object) do
        title { generate :digital_object_title }
        lang_materials { [build(:lang_material)] }
        digital_object_id { generate(:ref_id) }
        extents { [build(:extent)] }
        file_versions { [build(:file_version)] }
        dates { few_or_none(:date) }
        publish { true }
      end

      factory :digital_object_component, class: JSONModel(:digital_object_component) do
        component_id { generate(:alphanumstr) }
        title { generate :digital_object_component_title }
        digital_object { {'ref' => create(:digital_object).uri} }
      end

      factory :instance_digital, class: JSONModel(:instance) do
        instance_type { 'digital_object' }
        digital_object { { "ref" => create(:digital_object).uri } }
      end

      factory :file_version, class: JSONModel(:file_version) do
        file_uri { "http://example.com/1" }
        use_statement { generate(:use_statement) }
        xlink_actuate_attribute { generate(:xlink_actuate_attribute) }
        xlink_show_attribute { generate(:xlink_show_attribute) }
        file_format_name { generate(:file_format_name) }
        file_format_version { generate(:alphanumstr) }
        file_size_bytes { generate(:number).to_i }
        checksum { generate(:alphanumstr) }
        checksum_method { generate(:checksum_method) }
      end

      factory :lang_material, class: JSONModel(:lang_material) do
        language_and_script { build(:language_and_script) }
      end

      factory :lang_material_with_note, class: JSONModel(:lang_material) do
        notes { [build(:note_langmaterial)] }
      end

      factory :language_and_script, class: JSONModel(:language_and_script) do
        language { generate(:language) }
        script { generate(:script) }
      end

      factory :note_langmaterial, class: JSONModel(:note_langmaterial) do
        type { "langmaterial" }
        content { [ generate(:alphanumstr), generate(:alphanumstr) ] }
        publish { true }
      end

      factory :extent, class: JSONModel(:extent) do
        portion { "whole" }
        number { "1" }
        extent_type { "linear_feet" }
      end

      factory :date, class: JSONModel(:date) do
        date_type { generate(:date_type) }
        label { 'creation' }
        self.begin { "1900-01-01" }
        self.end { "1999-12-31" }
        expression { "1900s" }
      end

      factory :rde_template, class: JSONModel(:rde_template) do
        record_type { "archival_object" }
        name { generate(:rde_template_name) }
        order { [] }
        visible { ["colLevel", "colOtherLevel", "colTitle", "colCompId", "colLang", "colExpr", "colDType", "colDBegin", "colDEnd", "colIType", "colCType1", "colCInd1", "colCBarc1", "colCType2", "colCInd2", "colCType3", "colCInd3", "colNType1", "colNCont1", "colNType2", "colNCont2", "colNType3", "colNCont3"]}
        defaults { {
          "colTitle" => "DEFAULT TITLE",
          "colLevel" => "item"
        } }
      end

      factory :name_person, class: JSONModel(:name_person) do
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

      factory :agent_person, class: JSONModel(:agent_person) do
        agent_type { 'agent_person' }
        names { [build(:name_person)] }
        dates_of_existence { [build(:json_structured_date_label)] }
      end

      factory :agent_family, class: JSONModel(:agent_family) do
        agent_type { 'agent_family' }
        names { [build(:name_family)] }
        dates_of_existence { [build(:json_structured_date_label)] }
      end

      factory :agent_software, class: JSONModel(:agent_software) do
        agent_type { 'agent_software' }
        names { [build(:name_software)] }
        dates_of_existence { [build(:json_structured_date_label)] }
      end

      factory :agent_corporate_entity, class: JSONModel(:agent_corporate_entity) do
        agent_type { 'agent_corporate_entity' }
        names { [build(:name_corporate_entity)] }
        dates_of_existence { [build(:json_structured_date_label)] }
      end

      factory :name_corporate_entity, class: JSONModel(:name_corporate_entity) do
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

      factory :name_family, class: JSONModel(:name_family) do
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

      factory :name_software, class: JSONModel(:name_software) do
        rules { generate(:name_rule) }
        software_name { generate(:generic_name) }
        sort_name { generate(:sort_name) }
        sort_name_auto_generate { true }
      end

      factory :subject, class: JSONModel(:subject) do
        terms { [build(:term)] }
        vocabulary { create(:vocab).uri }
        authority_id { generate(:url) }
        scope_note { generate(:alphanumstr) }
        source { generate(:subject_source) }
      end

      factory :term, class: JSONModel(:term) do
        term { generate(:generic_term) }
        term_type { generate(:term_type) }
        vocabulary { create(:vocab).uri }
      end

      factory :top_container, class: JSONModel(:top_container) do
        indicator { generate(:top_container_indicator) }
      end

      factory :container_location, class: JSONModel(:container_location) do
        status { "current" }
        start_date { "2015-01-01" }
      end

      factory :location, class: JSONModel(:location) do
        building { generate(:building) }
        barcode { "8675309" }
      end

      factory :vocab, class: JSONModel(:vocabulary) do
        name { generate(:vocab_name) }
        ref_id { generate(:vocab_refid) }
      end

      factory :classification, class: JSONModel(:classification) do
        identifier { generate(:alphanumstr) }
        publish { true }
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
        extent_dimension { "width" }
        dimension_units { "inches" }
        width { "10" }
        height { "10" }
        depth { "10" }
      end

      factory :location_profile, class: JSONModel(:location_profile) do
        name { generate(:alphanumstr) }
        dimension_units { "inches" }
        width { "100" }
        height { "20" }
        depth { "20" }
      end
    end

    @@inited = true
  end
end
