require 'spec_helper'
require 'rails_helper'

describe 'Largetree toolbar tooltip', js: true do
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

  it 'should be hidden on edit resource page load' do
    click_link 'Browse'
    click_link 'Resources'
    find("#tabledSearchResults .btn-primary", match: :first).click

    expect(page).to have_css('#tt_load_via_spreadsheet', visible: :hidden)
  end

  it 'should be hidden on edit resource page when help button\'s neighboring buttons are hovered' do
    click_link 'Browse'
    click_link 'Resources'
    find("#tabledSearchResults .btn-primary", match: :first).click

    find_link('Enable Reorder Mode').hover
    expect(page).to have_css('#tt_load_via_spreadsheet', visible: :hidden)

    find_link('Add Child').hover
    expect(page).to have_css('#tt_load_via_spreadsheet', visible: :hidden)

    find_link('Load via Spreadsheet').hover
    expect(page).to have_css('#tt_load_via_spreadsheet', visible: :hidden)

    find_link('Rapid Data Entry').hover
    expect(page).to have_css('#tt_load_via_spreadsheet', visible: :hidden)
  end

  it 'should be visible on edit resource page when help button is hovered' do
    click_link 'Browse'
    click_link 'Resources'
    find("#tabledSearchResults .btn-primary", match: :first).click

    find('#load_via_spreadsheet_help_icon').hover
    expect(page).to have_css('#tt_load_via_spreadsheet', visible: true)
  end

  it 'should be hidden on edit archival object page load' do
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

    expect(page).to have_css('#tt_load_via_spreadsheet', visible: :hidden)
  end

  it 'should be hidden on edit archival object page when help button\'s neighboring buttons are hovered' do
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

    find_link('Enable Reorder Mode').hover
    expect(page).to have_css('#tt_load_via_spreadsheet', visible: :hidden)

    find_link('Add Child').hover
    expect(page).to have_css('#tt_load_via_spreadsheet', visible: :hidden)

    find_link('Add Sibling').hover
    expect(page).to have_css('#tt_load_via_spreadsheet', visible: :hidden)

    find_link('Load via Spreadsheet').hover
    expect(page).to have_css('#tt_load_via_spreadsheet', visible: :hidden)

    find_link('Transfer').hover
    expect(page).to have_css('#tt_load_via_spreadsheet', visible: :hidden)

    find_link('Rapid Data Entry').hover
    expect(page).to have_css('#tt_load_via_spreadsheet', visible: :hidden)
  end

  it 'should be visible on edit archival object page when help button is hovered' do
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

    find('#load_via_spreadsheet_help_icon').hover
    expect(page).to have_css('#tt_load_via_spreadsheet', visible: true)
  end

end
