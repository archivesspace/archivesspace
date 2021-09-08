# frozen_string_literal: true

require 'jsonmodel'
require 'factory_bot'
require 'spec/lib/factory_bot_helpers'

require_relative '../../common/selenium/backend_client_mixin'

include BackendClientMethods
include JSONModel


module Factories
  def self.init
    @@inited ||= false
    return true if @@inited

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

      sequence(:repo_code) {|n| "ASPACE REPO #{n} -- #{rand(1000000)}"}
      sequence(:repo_name) { |n| "Test Repo #{n}" }
      sequence(:generic_id) { |n| n.to_s }
      sequence(:accession_title) { |n| "Accession #{n}" }
      sequence(:ref_id) { |n| "aspace_#{n}" }

      factory :repo, class: JSONModel(:repository) do
        repo_code { generate :repo_code }
        name { generate :repo_name }
        org_code { '123' }
        image_url { 'http://foo.com/bar' }
        url { 'http://foo.com' }
      end

      factory :accession, class: JSONModel(:accession) do
        id_0 { generate(:generic_id) }
        id_1 { generate(:generic_id) }
        id_2 { generate(:generic_id) }
        id_3 { generate(:generic_id) }
        content_description { '9 guinea pigs' }
        condition_description { 'furious' }
        accession_date { '1990-01-01' }
      end

      factory :resource, class: JSONModel(:resource) do
        id_0 { generate(:generic_id) }
        id_1 { generate(:generic_id) }
        title { 'Generic Resource'}
        extents { [build(:extent)] }
        dates { [build(:date)] }
        level { 'collection' }
        lang_materials { [build(:json_lang_material)] }
        finding_aid_language { 'eng' }
        finding_aid_script { 'Latn' }
      end

      factory :json_lang_material, class: JSONModel(:lang_material) do
        language_and_script { build(:json_language_and_script) }
      end

      factory :json_language_and_script, class: JSONModel(:language_and_script) do
        language { 'eng' }
        script { 'Latn' }
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

      factory :archival_object, class: JSONModel(:archival_object) do
        ref_id { generate(:ref_id) }
        level { 'item' }
      end

      factory :digital_object, class: JSONModel(:digital_object) do
        lang_materials { [build(:json_lang_material)] }
        digital_object_id { generate(:ref_id) }
        extents { [build(:extent)] }
        dates { few_or_none(:date) }
      end
    end
  end
end
