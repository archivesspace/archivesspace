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
      sequence(:user_name) {|n| "Test User #{n} #{Time.now}"}

      sequence(:repo_code) {|n| "testrepo_#{n}_#{Time.now.to_i}"}
      sequence(:repo_name) {|n| "Test Repo #{n} #{Time.now}"}


      sequence(:ref_id) {|n| "aspace_#{n}"}
      sequence(:id_0) {|n| "#{Time.now.to_i}_#{n}"}

      sequence(:archival_object_title) {|n| "Archival Object #{n} - #{Time.now}"}

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


      factory :resource, class: JSONModel(:resource) do
        title "Resource #{Time.now}"
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

    end

    @@inited = true
  end
end
