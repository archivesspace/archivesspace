require 'spec_helper'
require 'rails_helper'

describe 'Collection Organization', js: true do
  describe 'Infinite Tree sidebar' do
    it 'should handle titles with mixed content appropriately' do
      @repo = create(:repo, repo_code: "infinite_tree_test_#{Time.now.to_i}")
      set_repo(@repo)
      @resource = create(:resource,
        title: 'This is <emph render="italic">a mixed content</emph> title',
        publish: true
      )
      @ao1 = create(:archival_object,
        resource: {'ref' => @resource.uri},
        title: 'This is <emph render="italic">another mixed content</emph> title',
        publish: true
      )
      @ao2 = create(:archival_object,
        resource: {'ref' => @resource.uri},
        title: 'This is not a mixed content title',
        publish: true
      )
      run_indexers

      visit "/repositories/#{@repo.id}/resources/#{@resource.id}/collection_organization"

      resource = find(".infinite-tree-sidebar #resource_#{@resource.id}")
      expect(resource).to have_css('.title[title="This is a mixed content title"]')
      resource_mixed_content_span = resource.find('.record-title > span.emph.render-italic')
      expect(resource_mixed_content_span).to have_content('a mixed content')

      ao1 = find(".infinite-tree-sidebar #archival_object_#{@ao1.id}")
      expect(ao1).to have_css('.title[title="This is another mixed content title"]')
      ao1_mixed_content_span = ao1.find('.record-title > span.emph.render-italic')
      expect(ao1_mixed_content_span).to have_content('another mixed content')

      ao2 = find(".infinite-tree-sidebar #archival_object_#{@ao2.id}")
      ao2_record_title = ao2.find('.record-title')
      expect(ao2_record_title).to_not have_css('span.emph.render-italic')
      expect(ao2_record_title).to have_content('This is not a mixed content title')
    end
  end
end
