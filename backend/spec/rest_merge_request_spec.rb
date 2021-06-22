# frozen_string_literal: true

require 'spec_helper'
require 'json'
# ./build/run backend:test -Dexample='Merge request API'

MERGEABLE_TYPES = ['subject', 'container_profile', 'top_container', 'resource', 'digital_object']
MERGEABLE_AGENT_TYPES = ['agent_corporate_entity', 'agent_family', 'agent_person', 'agent_software']

RSpec.describe 'Merge request API' do

  def pluralize_type(type)
    type = case type
           when 'agent_corporate_entity'
             'corporate_entities'
           when 'agent_family'
             'families'
           when 'agent_person'
             'people'
           when 'agent_software'
             'software'
           end
  end

  describe 'POST /merge_requests' do
    MERGEABLE_TYPES.each do |type|
      it "does a basic #{type} merge request" do
        repo = create(:repo)
        target = create(:"json_#{type}")
        victim = create(:"json_#{type}")

        payload = {'jsonmodel_type'=> "merge_request",
                   'victims'=> [
                     {'ref'=> "#{victim.uri}"}
                   ],
                   'target'=> {'ref'=> "#{target.uri}"}
                  }.to_json

        post "/merge_requests/#{type}?repo_id=#{repo.id}", payload

        expect(last_response.status).to eq(200)
        expect(JSON.parse(last_response.body)['status']).to match "Merged"
      end
    end
  end

  describe 'POST /merge_requests/agent_detail' do
    MERGEABLE_AGENT_TYPES.each do |type|
      it "does a detailed #{type} merge request with replacement" do
        target_name = build(:"json_name_#{type.delete_prefix('agent_')}")
        victim_name = build(:"json_name_#{type.delete_prefix('agent_')}")

        target = create(:"json_#{type}", :names => [target_name])
        victim = create(:"json_#{type}", :names => [victim_name])

        get "/agents/#{pluralize_type(type)}/#{victim.id}"
        victim_source = JSON.parse(last_response.body)['names'][0]['source']

        payload = {'jsonmodel_type'=> "merge_request_detail",
                   'victims'=> [
                     {'ref'=> "#{victim.uri}"}
                   ],
                   'target'=> {'ref'=> "#{target.uri}"},
                   'selections'=> { 'names.0.source'=> "REPLACE" }
                  }.to_json

        post '/merge_requests/agent_detail', payload
        expect(last_response.status).to eq(200)
        expect(JSON.parse(last_response.body)['status']).to match "Merged"

        # Also confirm the source has been replaced
        get "/agents/#{pluralize_type(type)}/#{target.id}"
        expect(JSON.parse(last_response.body)['names'][0]['source']).to match victim_source

      end

      it "does a dry run detailed #{type} merge request with replacement" do
        target_name = build(:"json_name_#{type.delete_prefix('agent_')}")
        victim_name = build(:"json_name_#{type.delete_prefix('agent_')}")

        target = create(:"json_#{type}", :names => [target_name])
        victim = create(:"json_#{type}", :names => [victim_name])

        get "/agents/#{pluralize_type(type)}/#{victim.id}"
        victim_source = JSON.parse(last_response.body)['names'][0]['source']

        payload = {'jsonmodel_type'=> "merge_request_detail",
                   'victims'=> [
                     {'ref'=> "#{victim.uri}"}
                   ],
                   'target'=> {'ref'=> "#{target.uri}"},
                   'selections'=> { 'names.0.source'=> "REPLACE" }
                  }.to_json

        post '/merge_requests/agent_detail?dry_run=true', payload
        expect(last_response.status).to eq(200)
        expect(JSON.parse(last_response.body)['status']).to match "Merged"

        # But the dry run merge didn't actually delete the victim
        get "/agents/#{pluralize_type(type)}/#{victim.id}"
        expect(last_response.status).to eq(200)

      end

    end
  end
end
