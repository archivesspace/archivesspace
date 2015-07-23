require 'factory_girl'
require 'jsonmodel'

include JSONModel


module SeleniumFactories

  def self.init

    @@inited ||= false

    if @@inited
      return true
    end

    JSONModel::init(:client_mode => true,
                    :url => AppConfig[:backend_url])



    FactoryGirl.define do

      to_create{|instance| instance.save}

      sequence(:username) {|n| "testuser_#{n}_#{Time.now.to_i}"}
      sequence(:user_name) {|n| "Test User #{n}"}

      sequence(:repo_code) {|n| "testrepo_#{n}_#{Time.now.to_i}"}
      sequence(:repo_name) {|n| "Test Repo #{n}"}
      sequence(:accession_id) {|n| "#{n}" }


      sequence(:ref_id) {|n| "aspace_#{n}"}
      sequence(:id_0) {|n| "#{Time.now.to_i}_#{n}"}

      sequence(:accession_title) { |n| "Accession #{n}" }
      sequence(:resource_title) { |n| "Resource #{n}" }
      sequence(:archival_object_title) {|n| "Archival Object #{n}"}

      sequence(:rde_template_name) {|n| "RDE Template #{n}_#{Time.now.to_i}"}

      factory :repo, class: JSONModel(:repository) do
        repo_code { generate :repo_code }
        name { generate :repo_name }
        org_code "123"
        image_url "http://foo.com/bar"
        url "http://foo.com"
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
        content_description "9 guinea pigs"
        condition_description "furious"
        accession_date "1990-01-01"
      end


      factory :collection_management, class: JSONModel(:collection_management) do
        processing_total_extent "10"
        processing_total_extent_type "cassettes"
        processing_hours_per_foot_estimate "80"
      end


      factory :resource, class: JSONModel(:resource) do
        title { generate :resource_title }
        id_0 { generate :id_0 }
        extents { [build(:extent)] }
        dates { [build(:date)] }
        level "collection"
        language "eng"
      end

      factory :archival_object, class: JSONModel(:archival_object) do
        title { generate(:archival_object_title) }
        ref_id { generate(:ref_id) }
        level "item"
      end

      factory :extent, class: JSONModel(:extent) do
        portion "whole"
        number "1"
        extent_type "linear_feet"
      end

      factory :date, class: JSONModel(:date) do
        date_type "inclusive"
        label 'creation'
        self.begin "1900-01-01"
        self.end "1999-12-31"
        expression "1900s"
      end

      factory :rde_template, class: JSONModel(:rde_template) do
        record_type "archival_object"
        name { generate(:rde_template_name) }
        order []
        visible { ["colLevel", "colOtherLevel", "colTitle", "colCompId", "colLang", "colExpr", "colDType", "colDBegin", "colDEnd", "colIType", "colCType1", "colCInd1", "colCBarc1", "colCType2", "colCInd2", "colCType3", "colCInd3", "colNType1", "colNCont1", "colNType2", "colNCont2", "colNType3", "colNCont3"]}
        defaults { {
          "colTitle" => "DEFAULT TITLE",
          "colLevel" => "item"
        } }
      end


    end

    @@inited = true
  end
end
