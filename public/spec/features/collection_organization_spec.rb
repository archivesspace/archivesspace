require 'spec_helper'
require 'rails_helper'

describe 'Collection Organization', js: true do
  before(:all) do
    @repo = create(:repo, repo_code: "collection_organization_test_#{Time.now.to_i}")
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
  end

  before(:each) do
    allow(AppConfig).to receive(:[]).and_call_original
  end

  describe 'Infinite Tree sidebar' do
    it 'should handle titles with mixed content appropriately' do
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

    it 'is positioned on the left side of the show and infinite views ' \
       'when AppConfig[:pui_collection_org_sidebar_position] is set to left' do
      allow(AppConfig).to receive(:[]).with(:pui_collection_org_sidebar_position) { 'left' }

      visit "/repositories/#{@repo.id}/resources/#{@resource.id}"

      sidebar = find('.infinite-tree-sidebar')
      content = find('.resizable-content-pane')

      sidebar_left_coordinate = page.evaluate_script('arguments[0].getBoundingClientRect().left', sidebar)
      sidebar_right_coordinate = page.evaluate_script('arguments[0].getBoundingClientRect().right', sidebar)
      content_left_coordinate = page.evaluate_script('arguments[0].getBoundingClientRect().left', content)

      expect(sidebar_left_coordinate).to be < content_left_coordinate
      expect(sidebar_right_coordinate).to eq content_left_coordinate

      visit "/repositories/#{@repo.id}/resources/#{@resource.id}/collection_organization"

      sidebar = find('.infinite-tree-sidebar')
      content = find('.infinite-records-container')

      sidebar_left_coordinate = page.evaluate_script('arguments[0].getBoundingClientRect().left', sidebar)
      sidebar_right_coordinate = page.evaluate_script('arguments[0].getBoundingClientRect().right', sidebar)
      content_left_coordinate = page.evaluate_script('arguments[0].getBoundingClientRect().left', content)

      expect(sidebar_left_coordinate).to be < content_left_coordinate
      expect(sidebar_right_coordinate).to eq content_left_coordinate
    end

    it 'is positioned on the right side of the show and infinite views ' \
       'when AppConfig[:pui_collection_org_sidebar_position] is set to right' do
      allow(AppConfig).to receive(:[]).with(:pui_collection_org_sidebar_position) { 'right' }

      visit "/repositories/#{@repo.id}/resources/#{@resource.id}"

      sidebar = find('.infinite-tree-sidebar')
      content = find('.resizable-content-pane')

      sidebar_left_coordinate = page.evaluate_script('arguments[0].getBoundingClientRect().left', sidebar)
      sidebar_right_coordinate = page.evaluate_script('arguments[0].getBoundingClientRect().right', sidebar)
      content_right_coordinate = page.evaluate_script('arguments[0].getBoundingClientRect().right', content)

      expect(sidebar_left_coordinate).to eq content_right_coordinate
      expect(sidebar_right_coordinate).to be > content_right_coordinate

      visit "/repositories/#{@repo.id}/resources/#{@resource.id}/collection_organization"

      sidebar = find('.infinite-tree-sidebar')
      content = find('.infinite-records-container')

      sidebar_left_coordinate = page.evaluate_script('arguments[0].getBoundingClientRect().left', sidebar)
      sidebar_right_coordinate = page.evaluate_script('arguments[0].getBoundingClientRect().right', sidebar)
      content_right_coordinate = page.evaluate_script('arguments[0].getBoundingClientRect().right', content)

      expect(sidebar_left_coordinate).to eq content_right_coordinate
      expect(sidebar_right_coordinate).to be > content_right_coordinate
    end

    it 'resizes appropriately via mouse drag when positioned on the left' do
      allow(AppConfig).to receive(:[]).with(:pui_collection_org_sidebar_position) { 'left' }
      visit "/repositories/#{@repo.id}/resources/#{@resource.id}/collection_organization"

      sidebar = find('.infinite-tree-sidebar')
      sidebar_handle = find('.resizable-sidebar-handle')
      content = find('.infinite-records-container')

      sidebar_left_initial = page.evaluate_script('arguments[0].getBoundingClientRect().left', sidebar)
      sidebar_right_initial = page.evaluate_script('arguments[0].getBoundingClientRect().right', sidebar)

      sidebar_handle.drag_to(content)

      sidebar_left_increase = page.evaluate_script('arguments[0].getBoundingClientRect().left', sidebar)
      sidebar_right_increase = page.evaluate_script('arguments[0].getBoundingClientRect().right', sidebar)
      expect(sidebar_left_increase).to eq sidebar_left_initial
      expect(sidebar_right_increase).to be > sidebar_right_initial

      sidebar_handle.drag_to(sidebar)

      sidebar_left_decrease = page.evaluate_script('arguments[0].getBoundingClientRect().left', sidebar)
      sidebar_right_decrease = page.evaluate_script('arguments[0].getBoundingClientRect().right', sidebar)
      expect(sidebar_left_decrease).to eq sidebar_left_initial
      expect(sidebar_right_decrease).to be < sidebar_right_increase
    end

    it 'resizes appropriately via mouse drag when positioned on the right' do
      allow(AppConfig).to receive(:[]).with(:pui_collection_org_sidebar_position) { 'right' }
      visit "/repositories/#{@repo.id}/resources/#{@resource.id}/collection_organization"

      sidebar = find('.infinite-tree-sidebar')
      sidebar_handle = find('.resizable-sidebar-handle')
      content = find('.infinite-records-container')

      sidebar_right_initial = page.evaluate_script('arguments[0].getBoundingClientRect().right', sidebar)
      sidebar_left_initial = page.evaluate_script('arguments[0].getBoundingClientRect().left', sidebar)

      sidebar_handle.drag_to(content)

      sidebar_right_increase = page.evaluate_script('arguments[0].getBoundingClientRect().right', sidebar)
      sidebar_left_increase = page.evaluate_script('arguments[0].getBoundingClientRect().left', sidebar)
      expect(sidebar_right_increase).to eq sidebar_right_initial
      expect(sidebar_left_increase).to be < sidebar_left_initial

      sidebar_handle.drag_to(sidebar)

      sidebar_right_decrease = page.evaluate_script('arguments[0].getBoundingClientRect().right', sidebar)
      sidebar_left_decrease = page.evaluate_script('arguments[0].getBoundingClientRect().left', sidebar)
      expect(sidebar_right_decrease).to eq sidebar_right_initial
      expect(sidebar_left_decrease).to be > sidebar_left_increase
    end

    it 'resizes appropriately via keyboard arrow keys when positioned on the left' do
      allow(AppConfig).to receive(:[]).with(:pui_collection_org_sidebar_position) { 'left' }
      visit "/repositories/#{@repo.id}/resources/#{@resource.id}/collection_organization"

      sidebar = find('.infinite-tree-sidebar')
      sidebar_handle = find('.resizable-sidebar-handle')
      content = find('.infinite-records-container')

      sidebar_left_initial = page.evaluate_script('arguments[0].getBoundingClientRect().left', sidebar)
      sidebar_right_initial = page.evaluate_script('arguments[0].getBoundingClientRect().right', sidebar)

      sidebar_handle.send_keys(:tab)
      sidebar_handle.send_keys(:up)

      sidebar_left_increase1 = page.evaluate_script('arguments[0].getBoundingClientRect().left', sidebar)
      sidebar_right_increase1 = page.evaluate_script('arguments[0].getBoundingClientRect().right', sidebar)
      expect(sidebar_left_increase1).to eq sidebar_left_initial
      expect(sidebar_right_increase1).to be > sidebar_right_initial

      sidebar_handle.send_keys(:down)

      sidebar_left_decrease1 = page.evaluate_script('arguments[0].getBoundingClientRect().left', sidebar)
      sidebar_right_decrease1 = page.evaluate_script('arguments[0].getBoundingClientRect().right', sidebar)
      expect(sidebar_left_decrease1).to eq sidebar_left_initial
      expect(sidebar_right_decrease1).to be < sidebar_right_increase1

      sidebar_handle.send_keys(:right)

      sidebar_left_increase2 = page.evaluate_script('arguments[0].getBoundingClientRect().left', sidebar)
      sidebar_right_increase2 = page.evaluate_script('arguments[0].getBoundingClientRect().right', sidebar)
      expect(sidebar_left_increase2).to eq sidebar_left_initial
      expect(sidebar_right_increase2).to be > sidebar_right_decrease1

      sidebar_handle.send_keys(:left)

      sidebar_left_decrease2 = page.evaluate_script('arguments[0].getBoundingClientRect().left', sidebar)
      sidebar_right_decrease2 = page.evaluate_script('arguments[0].getBoundingClientRect().right', sidebar)
      expect(sidebar_left_decrease2).to eq sidebar_left_initial
      expect(sidebar_right_decrease2).to be < sidebar_right_increase2
    end

    it 'resizes appropriately via keyboard arrow keys when positioned on the right' do
      allow(AppConfig).to receive(:[]).with(:pui_collection_org_sidebar_position) { 'right' }
      visit "/repositories/#{@repo.id}/resources/#{@resource.id}/collection_organization"

      sidebar = find('.infinite-tree-sidebar')
      sidebar_handle = find('.resizable-sidebar-handle')
      content = find('.infinite-records-container')

      sidebar_right_initial = page.evaluate_script('arguments[0].getBoundingClientRect().right', sidebar)
      sidebar_left_initial = page.evaluate_script('arguments[0].getBoundingClientRect().left', sidebar)

      sidebar_handle.send_keys(:tab)
      sidebar_handle.send_keys(:up)

      sidebar_right_increase1 = page.evaluate_script('arguments[0].getBoundingClientRect().right', sidebar)
      sidebar_left_increase1 = page.evaluate_script('arguments[0].getBoundingClientRect().left', sidebar)
      expect(sidebar_right_increase1).to eq sidebar_right_initial
      expect(sidebar_left_increase1).to be < sidebar_left_initial

      sidebar_handle.send_keys(:down)

      sidebar_right_decrease1 = page.evaluate_script('arguments[0].getBoundingClientRect().right', sidebar)
      sidebar_left_decrease1 = page.evaluate_script('arguments[0].getBoundingClientRect().left', sidebar)
      expect(sidebar_right_decrease1).to eq sidebar_right_initial
      expect(sidebar_left_decrease1).to be > sidebar_left_increase1

      sidebar_handle.send_keys(:left)

      sidebar_right_increase2 = page.evaluate_script('arguments[0].getBoundingClientRect().right', sidebar)
      sidebar_left_increase2 = page.evaluate_script('arguments[0].getBoundingClientRect().left', sidebar)
      expect(sidebar_right_increase2).to eq sidebar_right_initial
      expect(sidebar_left_increase2).to be < sidebar_left_decrease1

      sidebar_handle.send_keys(:right)

      sidebar_right_decrease2 = page.evaluate_script('arguments[0].getBoundingClientRect().right', sidebar)
      sidebar_left_decrease2 = page.evaluate_script('arguments[0].getBoundingClientRect().left', sidebar)
      expect(sidebar_right_decrease2).to eq sidebar_right_initial
      expect(sidebar_left_decrease2).to be > sidebar_left_increase2
    end
  end
end
