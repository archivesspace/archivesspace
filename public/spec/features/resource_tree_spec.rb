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
    run_indexers
  end

  before(:each) do
    allow(AppConfig).to receive(:[]).and_call_original
  end

  it "shows the record id in the tree if configured to do so" do
    allow(AppConfig).to receive(:[]).with(:pui_display_identifiers_in_resource_tree) { true }
    visit @resource.uri
    # don't do this! Capybara will wait for the first title to show up, the proceed and 'abc' will fail!
    #node_titles = find_all('.sidebar .record-title').map { |node| node.text }
    node_title_one = find('#tree-container .table-row:nth-child(1) .record-title').text
    node_title_two = find('#tree-container .table-row:nth-child(2) .record-title').text
    expect(node_title_one).to match /^1-2-3-4:/
    expect(node_title_two).to match /^abc:/
  end

  it "does not show the record id in the tree if not configured to do so" do
    allow(AppConfig).to receive(:[]).with(:pui_display_identifiers_in_resource_tree) { false }
    visit @resource.uri

    node_title_one = find('#tree-container .table-row:nth-child(1) .record-title').text
    node_title_two = find('#tree-container .table-row:nth-child(2) .record-title').text
    expect(node_title_one).not_to match /^1-2-3-4:/
    expect(node_title_two).not_to match /^abc:/
  end

end
