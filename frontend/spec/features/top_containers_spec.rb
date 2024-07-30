require 'spec_helper'
require 'rails_helper'

describe 'Top Containers and Instances', js: true do

  before :all do
    @repo = create :repo, repo_code: "containers_test_#{Time.now.to_i}"
    set_repo @repo

    @resource = create :resource
    @accession = create :accession
    @accession_no_container = create :accession

    @location_a = create :location
    @location_b = create :location, temporary: 'conservation'
    container_location = build :container_location, ref: @location_a.uri
    @container = create :top_container, container_locations: [container_location]

    # Some containers for searching
    ('A'..'E').each do |l|
      create :top_container,
             indicator: "Letter #{l}",
             container_locations: [container_location]
    end

    run_all_indexers
  end

  before :each do
    login_admin
    select_repository(@repo)
  end

  xit 'abides by search and browse column preferences' do
    visit '/'
    click_button id: 'user-menu-dropdown'
    click_link 'Global Preferences (admin)'
    select 'ILS Holding ID', from: 'preference[defaults][top_container_mgmt_browse_column_1]'
    select 'ILS Holding ID', from: 'preference[defaults][top_container_mgmt_sort_column]'

    click_button 'Save Preferences'
    visit '/top_containers'
    select 'No', from: 'exported'
    click_button 'Search'
    expect(find('th.header.headerSortDown')).to have_content('ILS Holding ID')
    expect(page).to have_content('ILS Holding ID')
  end

  xit 'searches containers and performs bulk operations' do
    visit '/top_containers'
    fill_in id: 'q', with: 'Letter'
    click_button 'Search'

    # the search param is added to the download csv button
    expect(first('a.searchExport')[:href]).to match(/q=Letter/)

    expect(page).to have_selector('#bulk_operation_results tbody tr', count: 5)

    # Now sort by indicator
    find('#bulk_operation_results th:nth-child(5)').click
    expect(find('#bulk_operation_results tbody tr:first-child td.top-container-indicator').text).to eq('Letter A')

    find('#bulk_operation_results tbody tr:first-child td:first-child input').click

    # Now bulk update Letter A's ILD #
    find('.bulk-operation-toolbar:first-child .dropdown-toggle').click
    find(id: 'bulkActionUpdateIlsHolding').click
    modal = find(id: 'bulkArchivalObjectUpdaterModal')
    modal.fill_in(id: 'ils_holding_id', with: 'xyzpdq')
    modal.find("button[type='submit']").click

    expect(modal.find('div.alert-success').text).to match(/Top .+ updated/)

    modal.find('.modal-footer button').click
    find('#bulk_operation_results tbody tr:first-child td:last-child a:first-child').click
    expect(find('.form-group:nth-child(3) div').text).to eq('xyzpdq')
  end

  xit 'performs bulk indicator update' do
    visit '/top_containers'
    select 'Yes', from: '#empty'
    find('input.btn').click
    find("#bulk_operation_results input[name='select_all']").click
    find('.bulk-operation-toolbar:first-child a.dropdown-toggle').click
    find(id: 'showBulkActionRapidIndicatorEntry').click
    modal = find(id: 'bulkActionIndicatorRapidEntryModal')
    modal
    # the original selenium test appears to have been left unfinished
  end

  xit 'searches containers and performs bulk container merge' do
    # Some containers for merging
    ('A'..'E').each do |l|
      create :top_container,
              indicator: "merge us #{l}"
    end
    run_index_round

    visit '/top_containers'
    fill_in id: 'q', with: 'merge us'
    find('input.btn').click
    find("#bulk_operation_results input[name='select_all']").click

    # Make sure multiple containers are present to merge
    expect(all('table tr').size).to be > 1

    # Now merge top containers
    find('.bulk-operation-toolbar:first-child .dropdown-toggle').click
    find('#bulkActionMerge').click
    modal = find('#bulkMergeModal')
    modal.first("input[name='target[]']").click
    modal.find('.merge-button').click

    # Should be given a confirmation modal
    modal = find('#bulkMergeConfirmModal')
    modal.find('.merge-button').click

    run_all_indexers

    # Should be redirected to surviving top container with success message
    expect(page).to have_content('Top Container(s) Merged')

    # need to reload to see results of indexing
    visit '/top_containers'
    expect(find_all('table tr').length).to be 2   # includes header row
  end

  xit 'remembers the search after leaving the page' do
    visit '/top_containers'
    fill_in id: 'q', with: 'Letter'
    find('input.btn').click
    n_results = all('tbody tr').length

    visit '/'
    visit '/top_containers'
    expect(find(id: 'q').value).to eq('Letter')
    expect(first('a.searchExport')['href']).to match(/q=Letter/)
    expect(all('tbody tr').length).to eq(n_results)
  end

  xit 'can attach instances to resources and create containers and locations along the way' do
    visit "#{@resource.uri.sub(%r{/repositories/\d+}, '')}/edit"
    find('#resource_instances_ .subrecord-form-heading .btn[data-instance-type="sub-container"]').click
    select 'Text', from: 'resource[instances][0][instance_type]'
    within find(id: 'resource_instances__0__container_') do
      find('[aria-label="Link to top container"]').click
      find('.linker-create-btn').click
    end

    within find(id: 'resource_instances__0__sub_container__top_container__ref__modal') do
      fill_in id: 'top_container_indicator_', with: 'foo'
      fill_in id: 'top_container_barcode_', with: "top container barcode #{Time.now.to_i}"
      find('[aria-label="Link to container profile"]').click
      find('.linker-create-btn').click
    end

    within find(id: 'top_container_container_profile__ref__modal') do
      fill_in id: 'container_profile_name_', with: "my profile #{Time.now.to_i}"
      fill_in id: 'container_profile_depth_', with: '.1'
      fill_in id: 'container_profile_height_', with: '0'
      fill_in id: 'container_profile_width_', with: '6.6'
      click_button('Create and Link')
    end

    within find(id: 'resource_instances__0__sub_container__top_container__ref__modal') do
      click_button('Add Location')

      expect(find(id: 'top_container_container_locations__0__start_date_')['value']).to eq(Time.now.strftime('%Y-%m-%d'))
      expect(find(id: 'top_container_container_locations__0__end_date_')['value']).to eq('')
    end

    find('.dropdown-toggle.locations').click
    find('.linker-create-btn').click

    within find(id: 'top_container_container_locations__0__ref__modal') do
      fill_in id: 'location_building_', with: '1234 Somewhere St'
      fill_in id: 'location_floor_', with: '12'
      fill_in id: 'location_room_', with: '123'
      fill_in id: 'location_coordinate_1_label_', with: 'Box XYZ'
      fill_in id: 'location_coordinate_1_indicator_', with: 'XYZ1234'
      click_button('createAndLinkButton')
    end
    click_button('Create and Link')
    fill_in id: 'resource_instances__0__sub_container__barcode_2_', with: 'test_child_container_barcode'
    click_button("Save Resource", match: :first).click

    expect(page).to have_content(/Resource .+ updated/)

    run_all_indexers

    # if created correctly, should be abe to find the top container by its associated sub_container barcode
    visit '/top_containers'
    fill_in id: 'q', with: ''
    select '', from: 'empty'
    fill_in id: 'barcodes', with: 'test_child_container_barcode'
    find('input.btn').click
    expect(page).to have_selector('#bulk_operation_results tbody tr')
  end

  xit 'can attach instances to accessions and create containers and locations along the way' do
    visit "#{@accession.uri.sub(%r{/repositories/\d+}, '')}/edit"
    find('#accession_instances_ .subrecord-form-heading .btn[data-instance-type="sub-container"]').click
    select 'Text', from: 'accession[instances][0][instance_type]'

    within find(id: 'accession_instances__0__container_') do
      find('[aria-label="Link to top container"]').click
      find('.linker-create-btn').click
    end

    within find(id: 'accession_instances__0__sub_container__top_container__ref__modal') do
      fill_in id: 'top_container_indicator_', with: 'oof'
      fill_in id: 'top_container_barcode_', with: "top container barcode #{Time.now.to_i}"
    end

    within find(id: 'accession_instances__0__sub_container__top_container__ref__modal') do
      click_button('Add Location')

      expect(find(id: 'top_container_container_locations__0__start_date_')['value']).to eq(Time.now.strftime('%Y-%m-%d'))
      expect(find(id: 'top_container_container_locations__0__end_date_')['value']).to eq('')
    end

    find('.dropdown-toggle.locations').click
    find('.linker-create-btn').click

    within find(id: 'top_container_container_locations__0__ref__modal') do
      fill_in id: 'location_building_', with: '1234 Somewhere St'
      fill_in id: 'location_floor_', with: '12'
      fill_in id: 'location_room_', with: '123'
      fill_in id: 'location_coordinate_1_label_', with: 'Box XYZ'
      fill_in id: 'location_coordinate_1_indicator_', with: 'XYZ1234'
      click_button('createAndLinkButton')
    end
    click_button('Create and Link')
    fill_in id: 'accession_instances__0__sub_container__barcode_2_', with: 'test_child_container_barcode'
    click_button("Save Accession", match: :first).click

    expect(page).to have_content('Accession updated')
  end

  xit 'can find the top container that was created using the typeahead feature for this record' do
    # TODO this example was ignored to get the Softserv updates merged into master;
    # the cause for this failing remotely but not locally is as yet unknown
    second_linker = '#accession_instances__1__sub_container__top_container__ref__combobox'
    run_all_indexers
    visit "#{@accession.uri.sub(%r{/repositories/\d+}, '')}/edit"
    find('#accession_instances_ .subrecord-form-heading .btn[data-instance-type="sub-container"]').click
    fill_in('token-input-accession_instances__1__sub_container__top_container__ref_', with: 'oof')
    expect(page).to have_selector("#{second_linker} .token-input-dropdown")
  end

  xit 'can add a location with a previous status to a top container' do
    visit "#{@container.uri.sub(%r{/repositories/\d+}, '')}/edit"
    click_button 'Add Location'
    find(id: 'top_container_container_locations__1__status_').select 'Previous'
    fill_in 'token-input-top_container_container_locations__1__ref_', with: @location_b.building
    dropdown_items = all('#top_container_container_locations__1__ref__listbox li')
    dropdown_items.first.click
    find('form .record-pane button[type="submit"]').click
    expect(find('div.record-pane div.error')).to have_content(/End Date.*Status.*Previous.*/)
    fill_in 'top_container_container_locations__1__end_date_', with: '2015-01-02'
    find('form .record-pane button[type="submit"]').click
    expect(find('div.record-pane div.alert-success')).to have_content('Top Container Updated')
  end

  xit 'can calculate extents for resources' do
    visit "#{@resource.uri.sub(%r{/repositories/\d+}, '')}/edit"
    find('#other-dropdown button').click
    click_button 'Calculate Extent'
    select 'Volumes', from: 'extent_extent_type_'
    click_button 'Create Extent'
    click_button 'Save'
    expect(page).to have_content(/\bResource\b.*\bupdated\b/)

    click_link 'Close Record'
    extent_headings = find_all('#resource_extents_ .panel-heading')
    expect(extent_headings.length).to eq 2
    expect(extent_headings[0].text).to match(/^\d.*/)
    expect(extent_headings[1].text).to match(/^\d.*/)
  end

  xit 'can calculate extents for accessions' do
    visit "#{@accession.uri.sub(%r{/repositories/\d+}, '')}/edit"
    find('#other-dropdown button').click
    click_button 'Calculate Extent'
    select 'Volumes', from: 'extent_extent_type_'
    click_button 'Create Extent'
    click_button 'Save'
    expect(page).to have_content(/\bAccession\b.*\bupdated\b/)

    visit @accession.uri.sub(%r{/repositories/\d+}, '')
    extent_headings = find_all('#accession_extents_ .panel-heading')

    expect(extent_headings.length).to eq 1
    expect(extent_headings[0].text).to match(/^\d.*/)
  end
end
