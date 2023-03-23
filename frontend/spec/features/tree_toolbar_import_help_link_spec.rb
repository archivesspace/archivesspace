require 'spec_helper'
require 'rails_helper'

$help_link_id = '#load_via_spreadsheet_help_icon'

describe 'Tree toolbar import help link', js: true do
  before(:all) do
    @repo = create(:repo, repo_code: "tree_toolbar_test_#{Time.now.to_i}")
    set_repo(@repo)
    @resource = create(:resource)
    parent = create(:json_archival_object,
           :resource => {'ref' => @resource.uri},
           :title => "Parent")
    create(:json_archival_object,
           :resource => {'ref' => @resource.uri},
           :parent => {'ref' => parent.uri},
           :title => "Child 1")

    run_indexer
  end

  before(:each) do
    login_admin
    select_repository(@repo)
    edit_resource(@resource)
  end

  after(:each) do
    #Capybara.current_session.instance_variable_set(:@touched, false)
  end

  it 'should be visible on edit resource page load' do
    expect(page).to have_css($help_link_id, visible: true)
  end

  it 'should display a tooltip above when hovered on edit resource page' do
    page.should have_no_css("#$help_link_id[aria-describedby*='tooltip']")
    page.find($help_link_id).hover
    page.should have_css("#$help_link_id[aria-describedby*='tooltip'][data-placement='top']")
  end

  it 'should be hidden when resource tree is in reorder mode' do
    click_on 'Enable Reorder Mode'
    expect(page).to have_css($help_link_id, visible: :hidden)
  end

  it 'should be visible on edit archival object page load' do
    within("#tree-container .table-row-group") do
      find("a.record-title").click
    end
    expect(page).to have_css($help_link_id, visible: true)
  end

  it 'should display a tooltip above when hovered on edit archival object page' do
    page.should have_no_css("#$help_link_id[aria-describedby*='tooltip']")
    page.find($help_link_id).hover
    page.should have_css("#$help_link_id[aria-describedby*='tooltip'][data-placement='top']")
  end

  it 'should be hidden when archival object tree is in reorder mode' do
    within("#tree-container .table-row-group") do
      find("a.record-title").click
    end

    click_on 'Enable Reorder Mode'
    expect(page).to have_css($help_link_id, visible: :hidden)
  end
end
