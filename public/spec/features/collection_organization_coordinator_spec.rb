require 'spec_helper'
require 'rails_helper'

describe 'Collection Organization Infinite Coordinator', js: true do
  before(:all) do
    @now = Time.now.to_i
    @repo = create(:repo, repo_code: "collection_organization_coordinatortest_#{@now}")
    set_repo(@repo)
    @resource = create(:resource, title: "Resource #{@now}", publish: true)
    @ao1 = create(:archival_object,
      resource: {'ref' => @resource.uri},
      publish: true
    )
    @ao2 = create(:archival_object,
      resource: {'ref' => @resource.uri},
      publish: true
    )

  31.times do |i| # 2 batches
      instance_variable_set("@ao#{i + 1}_of_ao2", create(:archival_object,
        resource: {'ref' => @resource.uri},
        parent: {'ref' => @ao2.uri},
        publish: true
      ))
    end

    run_indexers
  end

  before(:each) do
    visit "#{@resource.uri}/collection_organization"
    @records_container = find('#infinite-records-container')
    @ao1_record = @records_container.find("[data-uri='#{@ao1.uri}']")
    @ao2_record = @records_container.find("[data-uri='#{@ao2.uri}']")
    @tree_container = find('#infinite-tree-container')
    @ao2_expand_btn = @tree_container.find("[data-uri='#{@ao2.uri}'] .node-expand")
  end

  describe 'shares current record state between InfiniteTree and InfiniteRecords' do
    it 'should change the current tree node when the current record changes via scroll' do
      expect(@tree_container).to have_css('.root.current')
      @records_container.scroll_to(@ao1_record, align: :top)
      expect(@tree_container).to have_css("[data-uri='#{@ao1.uri}'].current")
      expect(@tree_container).not_to have_css('.root.current')

      @records_container.scroll_to(@ao2_record, align: :top)
      expect(@tree_container).to have_css("[data-uri='#{@ao2.uri}'].current")
      expect(@tree_container).to have_css('.current', count: 1)
    end

    describe 'helps identify the current tree node' do
      it 'when its batch is initially rendered on parent expansion' do
        ao1_of_ao2_record = @records_container.find("[data-uri='#{@ao1_of_ao2.uri}']")
        @records_container.scroll_to(ao1_of_ao2_record, align: :top)
        expect(@tree_container).not_to have_css('.current')
        @ao2_expand_btn.click
        expect(@tree_container).to have_css("[data-uri='#{@ao1_of_ao2.uri}'].current")
      end

      it 'when its batch is rendered on scroll' do
        page.find('.load-all__label-toggle').click
        last_record_uri = @ao31_of_ao2.uri
        last_record = @records_container.find("[data-uri='#{last_record_uri}']")
        @records_container.scroll_to(last_record, align: :top)
        @ao2_expand_btn.click
        observer_node = @tree_container.find('[data-observe-next-batch]')
        expect(@tree_container).not_to have_css('.current')
        @tree_container.scroll_to(observer_node, align: :center)
        expect(@tree_container).to have_css("[data-uri='#{last_record_uri}'].current")
      end
    end
  end
end
