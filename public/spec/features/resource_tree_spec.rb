require 'spec_helper'
require 'rails_helper'

describe 'Resource Tree', js: true do
  before(:all) do
    @repo = create(:repo, repo_code: "resource_tree_test_#{Time.now.to_i}")
    set_repo(@repo)
    @resource = create(:resource, id_0: "1", id_1: "2", id_2: "3", id_3: "4", publish: true)
    @ao = create(:json_archival_object,
                 resource: {'ref' => @resource.uri},
                 title: "Component",
                 component_id: "abc",
                 publish: true
                )
    @series = create(:archival_object, title: 'series', level: 'series', resource: {ref: @resource.uri}, publish: true)
    @item = create(:archival_object,
                  title: 'item',
                  level: 'item',
                  resource: {ref: @resource.uri}, parent: {ref: @series.uri},
                  publish: true
                 )

    run_indexers
  end

  before(:each) do
    allow(AppConfig).to receive(:[]).and_call_original
  end

  it "shows the record id in the tree if configured to do so" do
    allow(AppConfig).to receive(:[]).with(:pui_display_identifiers_in_resource_tree) { true }
    visit @resource.uri

    within "#record-tree-container" do
      aggregate_failures "marks the tree up as nested lists" do
        expect(page).to have_css("ol.infinite-tree > li.root#resource_#{@resource.id} > .node-row .node-title")
        expect(page).not_to have_css('[role]')
      end

      find("#archival_object_#{@series.id} > .node-row .node-expand").click

      expect(page).to have_css(
        "#archival_object_#{@series.id} > ol.node-children > li#archival_object_#{@item.id}"
      )
    end

    expect(page).to have_text('1-2-3-4:')
    expect(page).to have_text('abc:')
  end

  it "does not show the record id in the tree if not configured to do so" do
    allow(AppConfig).to receive(:[]).with(:pui_display_identifiers_in_resource_tree) { false }
    visit @resource.uri

    within "#record-tree-container" do
      expect(page).to have_css("li#archival_object_#{@ao.id} .node-title", text: 'Component')
    end

    expect(page).not_to have_text('1-2-3-4:')
    expect(page).not_to have_text('abc:')
  end
end
