require 'spec_helper'
require 'rails_helper'

$help_link_id = '#load_via_spreadsheet_help_icon'

describe 'Tree toolbar import help link', js: true do
  before(:each) do
    visit '/'
    page.has_xpath? '//input[@id="login"]'
    within "form.login" do
      fill_in "username", with: "admin"
      fill_in "password", with: "admin"
      click_button "Sign In"
    end

    page.has_no_xpath? '//input[@id="login"]'
  end

  it 'should be visible on edit resource page load' do
    click_link 'Browse'
    click_link 'Resources'
    find("#tabledSearchResults .btn-primary", match: :first).click

    expect(page).to have_css($help_link_id, visible: true)
  end

  it 'should display a tooltip above when hovered on edit resource page' do
    click_link 'Browse'
    click_link 'Resources'
    find("#tabledSearchResults .btn-primary", match: :first).click

    page.should have_no_css("#$help_link_id[aria-describedby*='tooltip']")
    page.find($help_link_id).hover
    page.should have_css("#$help_link_id[aria-describedby*='tooltip'][data-placement='top']")
  end

  it 'should be hidden when resource tree is in reorder mode' do
    click_link 'Browse'
    click_link 'Resources'
    find("#tabledSearchResults .btn-primary", match: :first).click

    click_on 'Enable Reorder Mode'
    expect(page).to have_css($help_link_id, visible: :hidden)
  end

  it 'should be visible on edit archival object page load' do
    @resource = create(:json_resource)
    @parent = create(:json_archival_object,
                     :resource => {'ref' => @resource.uri},
                     :title => "Parent")
    @child1 = create(:json_archival_object,
                     :resource => {'ref' => @resource.uri},
                     :parent => {'ref' => @parent.uri},
                     :title => "Child 1")

    $index.run_index_round

    click_link 'Browse'
    click_link 'Resources'
    within('table#tabledSearchResults > tbody > tr:nth-of-type(2)') do
      find(".btn-primary").click
    end

    within("#tree-container .table-row-group") do
      find("a.record-title").click
    end

    expect(page).to have_css($help_link_id, visible: true)
  end

  it 'should display a tooltip above when hovered on edit archival object page' do
    @resource = create(:json_resource)
    @parent = create(:json_archival_object,
                     :resource => {'ref' => @resource.uri},
                     :title => "Parent")
    @child1 = create(:json_archival_object,
                     :resource => {'ref' => @resource.uri},
                     :parent => {'ref' => @parent.uri},
                     :title => "Child 1")

    $index.run_index_round

    click_link 'Browse'
    click_link 'Resources'
    within('table#tabledSearchResults > tbody > tr:nth-of-type(2)') do
      find(".btn-primary").click
    end

    within("#tree-container .table-row-group") do
      find("a.record-title").click
    end

    page.should have_no_css("#$help_link_id[aria-describedby*='tooltip']")
    page.find($help_link_id).hover
    page.should have_css("#$help_link_id[aria-describedby*='tooltip'][data-placement='top']")
  end

  it 'should be hidden when archival object tree is in reorder mode' do
    @resource = create(:json_resource)
    @parent = create(:json_archival_object,
                     :resource => {'ref' => @resource.uri},
                     :title => "Parent")
    @child1 = create(:json_archival_object,
                     :resource => {'ref' => @resource.uri},
                     :parent => {'ref' => @parent.uri},
                     :title => "Child 1")

    $index.run_index_round

    click_link 'Browse'
    click_link 'Resources'
    within('table#tabledSearchResults > tbody > tr:nth-of-type(2)') do
      find(".btn-primary").click
    end

    within("#tree-container .table-row-group") do
      find("a.record-title").click
    end

    click_on 'Enable Reorder Mode'
    expect(page).to have_css($help_link_id, visible: :hidden)
  end

end
