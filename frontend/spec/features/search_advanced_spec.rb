# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Advanced Search', js: true do
  before(:all) do
    @now = Time.now.to_i
    @repository = create(:repo, repo_code: "adv_search_test_#{@now}", publish: true)
    set_repo @repository

    @keywords = (0..9).to_a.map { SecureRandom.hex }

    @accession_1 = create(:accession, title: "#{@keywords[0]} #{@keywords[4]}", publish: true)
    @accession_2 = create(:accession, title: "#{@keywords[1]} #{@keywords[5]}", publish: false)
    @resource_1 = create(:resource, title: "#{@keywords[0]} #{@keywords[6]}", publish: false)
    @resource_2 = create(:resource, title: "#{@keywords[2]} #{@keywords[7]}", publish: true)
    @digital_object_1 = create(:digital_object, title: "#{@keywords[0]} #{@keywords[8]}")
    @digital_object_2 = create(:digital_object, title: "#{@keywords[3]} #{@keywords[9]}")

    @viewer_user = create_user(@repository => ['repository-viewers'])

    run_index_round
  end

  before(:each) do
    login_user(@viewer_user)
    select_repository(@repository)
  end

  it 'is available via the navbar and renders when toggled' do
    find('.navbar .search-switcher').click
    find('.search-switcher-hide')
  end

  it 'finds matches with one keyword field query' do
    find('.navbar .search-switcher').click
    find('.search-switcher-hide')

    element = find('#v0')
    element.fill_in with: @keywords[0]

    click_on 'Search'

    find(:xpath, "//table//tr[contains(., '#{@accession_1.title}')]")
    find(:xpath, "//table//tr[contains(., '#{@resource_1.title}')]")
    find(:xpath, "//table//tr[contains(., '#{@digital_object_1.title}')]")

    expect(page).to_not have_text @accession_2.title
    expect(page).to_not have_text @resource_2.title
    expect(page).to_not have_text @digital_object_2.title
  end

  it 'finds single match with two keyword ANDed field queries' do
    find('.navbar .search-switcher').click
    find('.search-switcher-hide')

    find('.advanced-search-add-row-dropdown').click
    find('.advanced-search-add-text-row').click

    find('#v0').fill_in with: @keywords[0]
    find('#v1').fill_in with: @keywords[4]
    select 'Title', from: 'f1'

    click_on 'Search'

    find(:xpath, "//table//tr[contains(., '#{@accession_1.title}')]")

    expect(page).to_not have_text @resource_1.title
    expect(page).to_not have_text @digital_object_1.title
    expect(page).to_not have_text @accession_2.title
    expect(page).to_not have_text @resource_2.title
    expect(page).to_not have_text @digital_object_2.title
  end

  it 'finds matches with two keyword ORed field queries' do
    find('.navbar .search-switcher').click
    find('.search-switcher-hide')

    find('.advanced-search-add-row-dropdown').click
    find('.advanced-search-add-text-row').click
    find('#v0').fill_in with: @keywords[0]
    find('#v1').fill_in with: @keywords[4]
    select 'Title', from: 'f1'
    select 'Or', from: 'op1'

    click_on 'Search'

    find(:xpath, "//table//tr[contains(., '#{@accession_1.title}')]")
    find(:xpath, "//table//tr[contains(., '#{@resource_1.title}')]")
    find(:xpath, "//table//tr[contains(., '#{@digital_object_1.title}')]")

    expect(page).to_not have_text @accession_2.title
    expect(page).to_not have_text @resource_2.title
    expect(page).to_not have_text @digital_object_2.title
  end

  it 'finds matches with two keyword joined AND NOTed field queries' do
    find('.navbar .search-switcher').click
    find('.search-switcher-hide')
    find('.advanced-search-add-row-dropdown').click
    find('.advanced-search-add-text-row').click
    find('#v0').fill_in with: @keywords[0]
    find('#v1').fill_in with: @keywords[4]
    select 'Title', from: 'f1'
    select 'Not', from: 'op1'

    click_on 'Search'

    find(:xpath, "//table//tr[contains(., '#{@resource_1.title}')]")
    find(:xpath, "//table//tr[contains(., '#{@digital_object_1.title}')]")

    expect(page).to_not have_text @accession_1.title
    expect(page).to_not have_text @accession_2.title
    expect(page).to_not have_text @resource_2.title
    expect(page).to_not have_text @digital_object_2.title
  end

  it 'clear resets the fields' do
    find('.navbar .search-switcher').click
    find('.search-switcher-hide')
    find('.advanced-search-add-row-dropdown').click
    find('.advanced-search-add-text-row').click

    find('#v0').fill_in with: @keywords[0]
    find('#v1').fill_in with: @keywords[4]
    select 'Title', from: 'f1'
    select 'Not', from: 'op1'

    click_on 'Search'
    click_on 'Clear'
    expect(find('#v0').value).to eq('')
  end

  it 'allow adding of mulitple rows of the same type' do
    find('.navbar .search-switcher').click
    find('.search-switcher-hide')
    find('.advanced-search-add-row-dropdown').click
    find('.advanced-search-add-bool-row').click

    find('.advanced-search-add-row-dropdown').click
    find('.advanced-search-add-bool-row').click

    expect(page).to have_css('#v1')
    expect(page).to have_css('#v2')
  end

  it 'filters records based on a boolean search' do
    find('.navbar .search-switcher').click
    find('.search-switcher-hide')

    find('#v0').fill_in with: @keywords[0]
    select 'Title', from: 'f0'

    click_on 'Search'

    find(:xpath, "//table//tr[contains(., '#{@resource_1.title}')]")
    find(:xpath, "//table//tr[contains(., '#{@accession_1.title}')]")

    find('.advanced-search-add-row-dropdown').click
    find('.advanced-search-add-bool-row').click

    select 'Published', from: 'f1'
    select 'False', from: 'v1'

    click_on 'Search'

    find(:xpath, "//table//tr[contains(., '#{@resource_1.title}')]")
    expect(page).to_not have_text @accession_1.title

    select 'True', from: 'v1'

    click_on 'Search'

    find(:xpath, "//table//tr[contains(., '#{@accession_1.title}')]")
    expect(page).to_not have_text @resource_1.title
  end

  it 'filters records based on a date field search' do
    find('.navbar .search-switcher').click
    find('.search-switcher-hide')

    find('#v0').fill_in with: @keywords[0]
    select 'Title', from: 'f0'

    find('.advanced-search-add-row-dropdown').click
    find('.advanced-search-add-bool-row').click

    select 'Published', from: 'f1'
    select 'True', from: 'v1'

    find('.advanced-search-add-row-dropdown').click
    find('.advanced-search-add-date-row').click

    element = find('#v2')
    element.fill_in with: '2012-01-01'

    select 'And', from: 'op2'
    select 'Created', from: 'f2'
    select 'greater than', from: 'dop2'

    click_on 'Search'

    find(:xpath, "//table//tr[contains(., '#{@accession_1.title}')]")

    select 'less than', from: 'dop2'

    click_on 'Search'

    expect(page).to have_text 'No records found'
  end

  it 'hides when toggled' do
    find('.navbar .search-switcher').click
    find('.search-switcher-hide')

    find('form.advanced-search')

    click_on 'Hide Advanced Search'

    expect(page.has_no_css?('form.advanced-search', visible: :visible)).to eq(true)
  end

  it "doesn't display when a normal search is performed" do
    element = find('#global-search-box')
    element.fill_in with: @keywords[0]
    find('#global-search-button').click

    expect(page.has_no_css?('form.advanced-search', visible: :visible)).to eq(true)
  end
end
