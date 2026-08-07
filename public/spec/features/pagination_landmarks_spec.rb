# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Pagination landmarks', js: true do
  before(:all) do
    @now = Time.now.to_i

    @repo = create(:repo, repo_code: "pagination_landmarks_#{@now}", publish: true)
    set_repo @repo

    2.times do |i|
      create(:resource, title: "Pagination Landmark Resource #{i} #{@now}", publish: true)
    end

    @repo2 = create(:repo, repo_code: "pagination_landmarks_b_#{@now}", publish: true)
    set_repo @repo2
    create(:resource, title: "Pagination Landmark Repo B Resource #{@now}", publish: true)

    set_repo @repo

    @agent = create(:agent_person,
                    names: [build(:name_person,
                                  primary_name: "Pagination Agent #{@now}",
                                  sort_name: "Pagination Agent #{@now}")],
                    publish: true)

    2.times do |i|
      create(:resource,
             title: "Pagination Agent Resource #{i} #{@now}",
             publish: true,
             linked_agents: [{ 'role' => 'creator', 'ref' => @agent.uri }])
    end

    @subject = create(:subject, terms: [build(:term, term: "Pagination Subject #{@now}")])

    2.times do |i|
      create(:resource,
             title: "Pagination Subject Resource #{i} #{@now}",
             publish: true,
             subjects: [{ 'ref' => @subject.uri }])
    end

    @classification = create(:classification,
                             title: "Pagination Classification #{@now}",
                             publish: true)

    create(:classification, title: "Pagination Classification Two #{@now}", publish: true)

    2.times do |i|
      create(:resource,
             title: "Pagination Classification Resource #{i} #{@now}",
             publish: true,
             classifications: [{ 'ref' => @classification.uri }])
    end

    2.times do |i|
      create(:accession, title: "Pagination Accession #{i} #{@now}", publish: true)
    end

    2.times do |i|
      create(:archival_object,
             title: "Pagination Record #{i} #{@now}",
             publish: true,
             resource: { 'ref' => create(:resource, publish: true).uri })
    end

    @inventory_resource = create(:resource,
                                 title: "Pagination Inventory Resource #{@now}",
                                 publish: true)

    2.times do |i|
      top_container = create(:json_top_container, indicator: "Pagination Box #{i} #{@now}", type: 'box')
      create(:archival_object,
             title: "Pagination Inventory AO #{i} #{@now}",
             resource: { 'ref' => @inventory_resource.uri },
             publish: true,
             instances: [build(:json_instance, {
               instance_type: 'text',
               sub_container: build(:json_sub_container, {
                 top_container: { ref: top_container.uri },
                 type_2: 'folder',
                 indicator_2: '1'
               })
             })])
    end

    @digitized_resource = create(:resource,
                                 title: "Pagination Digitized Resource #{@now}",
                                 publish: true)

    2.times do |i|
      digital_object = create(:digital_object,
                              title: "Pagination Digital Object #{i} #{@now}",
                              publish: true,
                              file_versions: [build(:file_version, {
                                publish: true,
                                is_representative: true,
                                use_statement: 'image-service'
                              })])

      @digitized_resource.instances << build(:instance_digital, {
        digital_object: { ref: digital_object.uri },
        is_representative: (i == 0)
      })
    end
    @digitized_resource.save

    @top_container = create(:json_top_container, indicator: "Pagination Shared Box #{@now}", type: 'box')

    2.times do |i|
      create(:archival_object,
             title: "Pagination Container AO #{i} #{@now}",
             publish: true,
             resource: { 'ref' => create(:resource, publish: true).uri },
             instances: [build(:json_instance, {
               instance_type: 'text',
               sub_container: build(:json_sub_container, {
                 top_container: { ref: @top_container.uri },
                 type_2: 'folder',
                 indicator_2: '1'
               })
             })])
    end

    run_indexers
  end

  context 'with two pagination blocks' do
    describe 'search results views' do
      {
        'resources index' => '/repositories/resources?page_size=1',
        'agents index' => '/agents?page_size=1',
        'subjects index' => '/subjects?page_size=1',
        'classifications index' => '/classifications?page_size=1',
        'accessions index' => '/accessions?page_size=1',
        'objects index' => '/objects?page_size=1',
        'search results' => '/search?q[]=*&op[]=OR&field[]=title&page_size=1'
      }.each do |label, path|
        context label do
          let(:pagination_path) { path }

          it_behaves_like 'having two distinct pagination landmarks'
        end
      end
    end

    describe 'repositories index view' do
      let(:pagination_path) { '/repositories?page_size=1' }

      it_behaves_like 'having two distinct pagination landmarks'
    end

    describe 'agent show view' do
      let(:pagination_path) { "/agents/people/#{@agent.id}?page_size=1" }

      it_behaves_like 'having two distinct pagination landmarks'
    end

    describe 'subject show view' do
      let(:pagination_path) { "/subjects/#{@subject.id}?page_size=1" }

      it_behaves_like 'having two distinct pagination landmarks'
    end
  end

  context 'with one pagination block' do
    describe 'container show view' do
      let(:pagination_path) do
        "/repositories/#{@repo.id}/top_containers/#{@top_container.id}?page_size=1"
      end

      it_behaves_like 'having one pagination landmark'
    end

    describe 'classification show view' do
      let(:pagination_path) do
        "/repositories/#{@repo.id}/classifications/#{@classification.id}?page_size=1"
      end

      it_behaves_like 'having one pagination landmark'
    end

    describe 'resource inventory view' do
      let(:pagination_path) do
        "/repositories/#{@repo.id}/resources/#{@inventory_resource.id}/inventory?page_size=1"
      end

      it_behaves_like 'having one pagination landmark'
    end

    describe 'resource digitized view' do
      let(:pagination_path) do
        "/repositories/#{@repo.id}/resources/#{@digitized_resource.id}/digitized?page_size=1"
      end

      it_behaves_like 'having one pagination landmark'
    end
  end
end
