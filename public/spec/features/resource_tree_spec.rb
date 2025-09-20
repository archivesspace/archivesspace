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

    aggregate_failures "marks visual lists as such" do
      page.has_css? "div#tree-container"
      within "div#tree-container" do
        expect(page).to have_xpath("div[@role='list']")
        expect(page).to have_xpath("div[@role='list']/div[@role='listitem'][@id='resource_#{@resource.id}']")
        first(".expandme-icon").click
        expect(page).to have_xpath("div[@role='list']/div[@role='list']/div[@role='list']/div[@role='listitem'][@id='archival_object_#{@item.id}']")
      end
    end

    expect(page).to have_text('1-2-3-4:')
    expect(page).to have_text('abc:')
  end

  it "does not show the record id in the tree if not configured to do so" do
    allow(AppConfig).to receive(:[]).with(:pui_display_identifiers_in_resource_tree) { false }
    visit @resource.uri

    expect(page).not_to have_text('1-2-3-4:')
    expect(page).not_to have_text('abc:')
  end
end
