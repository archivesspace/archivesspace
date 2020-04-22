# frozen_string_literal: true

require_relative '../spec_helper'

describe 'Locations' do
  before(:all) do
    @repo = create(:repo, repo_code: "locations_test_#{Time.now.to_i}")
    set_repo(@repo)

    @manager_user = create_user(@repo => ['repository-managers'])
    @archivist_user = create_user(@repo => ['repository-archivists'])

    @driver = Driver.get.login_to_repo(@manager_user, @repo)
  end

  after(:all) do
    @driver ? @driver.quit : next
  end

  it 'allows access to the single location form' do
    @driver.find_element(:link, 'Create').click
    @driver.find_element(:link, 'Location').click
    @driver.click_and_wait_until_gone(:link, 'Single Location')
    expect(@driver.find_element(:css, 'h2').text).to eq('New Location Location')
  end

  it 'displays error messages upon invalid location' do
    @driver.click_and_wait_until_gone(css: 'form#new_location .btn-primary')

    @driver.find_element_with_text('//div[contains(@class, "error")]', /Building - Property is required but was missing/)

    @driver.clear_and_send_keys([:id, 'location_building_'], '329 W. 81st St')
    @driver.click_and_wait_until_gone(css: 'form#new_location .btn-primary')

    @driver.find_element_with_text('//div[contains(@class, "error")]', /You must either specify a barcode, a classification, or both a coordinate 1 label and coordinate 1 indicator/)
  end

  it 'saves a valid location' do
    @driver.clear_and_send_keys([:id, 'location_floor_'], '5')
    @driver.clear_and_send_keys([:id, 'location_room_'], '5 MOO')

    @driver.clear_and_send_keys([:id, 'location_coordinate_1_label_'], 'Box XYZ')
    @driver.clear_and_send_keys([:id, 'location_coordinate_1_indicator_'], 'XYZ0001')

    @driver.click_and_wait_until_gone(css: 'form#new_location .btn-primary')

    @driver.find_element_with_text('//div[contains(@class, "alert-success")]', /Location Created/)
  end

  it 'allows locations to be edited' do
    @driver.clear_and_send_keys([:id, 'location_room_'], '5A')
    @driver.click_and_wait_until_gone(css: 'form#new_location .btn-primary')

    @driver.find_element_with_text('//div[contains(@class, "alert-success")]', /Location Saved/)
  end

  it 'lists the new location in the browse list' do
    run_index_round

    @driver.get($frontend)

    @driver.find_element(:link, 'Browse').click
    @driver.wait_for_dropdown
    @driver.click_and_wait_until_gone(:link, 'Locations')

    @driver.find_paginated_element(xpath: "//tr[.//*[contains(text(), '329 W. 81st St, 5, 5A [Box XYZ: XYZ0001]')]]")
  end

  it 'allows the new location to be viewed in non-edit mode' do
    @driver.get($frontend)

    @driver.find_element(:link, 'Browse').click
    @driver.wait_for_dropdown
    @driver.click_and_wait_until_gone(:link, 'Locations')
    @driver.clear_and_send_keys([:css, '.sidebar input.text-filter-field'], '329*')
    @driver.click_and_wait_until_gone(:css, '.sidebar input.text-filter-field + div button')
    @driver.click_and_wait_until_gone(:link, 'Edit')
    assert(5) { expect(@driver.find_element(:css, '.record-pane h2').text).to match(/329 W\. 81st St/) }
  end

  it 'allows creation of a location with plus one stickies' do
    @driver.get($frontend)

    @driver.find_element(:link, 'Create').click
    @driver.wait_for_dropdown
    @driver.find_element(:link, 'Location').click

    @driver.click_and_wait_until_gone(:link, 'Single Location')
    @driver.clear_and_send_keys([:id, 'location_building_'], '523 Fake St')
    @driver.clear_and_send_keys([:id, 'location_floor_'], '13')
    @driver.clear_and_send_keys([:id, 'location_room_'], '237')
    @driver.clear_and_send_keys([:id, 'location_area_'], '37')

    @driver.clear_and_send_keys([:id, 'location_coordinate_1_label_'], 'Box ABC')
    @driver.clear_and_send_keys([:id, 'location_coordinate_1_indicator_'], 'ABC0001')

    @driver.click_and_wait_until_gone(css: 'form#new_location .createPlusOneBtn')

    @driver.wait_for_ajax

    expect do
      assert(5) do
        @driver.find_element_with_text('//div[contains(@class, "alert-success")]', /Location Created/)
      end
    end.not_to raise_error

    # these are sticky
    assert(5) { expect(@driver.find_element(:id, 'location_building_').attribute('value')).to eq('523 Fake St') }
    assert(5) { expect(@driver.find_element(:id, 'location_floor_').attribute('value')).to eq('13') }
    assert(5) { expect(@driver.find_element(:id, 'location_room_').attribute('value')).to eq('237') }
    assert(5) { expect(@driver.find_element(:id, 'location_area_').attribute('value')).to eq('37') }

    # these are not
    assert(5) { expect(@driver.find_element(:id, 'location_coordinate_1_label_').attribute('value')).to eq('') }
    assert(5) { expect(@driver.find_element(:id, 'location_coordinate_1_indicator_').attribute('value')).to eq('') }
  end

  it 'lists the new location for an archivist' do
    @driver.logout.login(@archivist_user)

    @driver.find_element(:link, 'Browse').click
    @driver.wait_for_dropdown
    @driver.click_and_wait_until_gone(:link, 'Locations')

    @driver.find_paginated_element(xpath: "//tr[.//*[contains(text(), '329 W. 81st St, 5, 5A [Box XYZ: XYZ0001]')]]")
  end

  it "doesn't offer location edit actions to an archivist" do
    assert(20) do
      @driver.ensure_no_such_element(:link, 'Create Location')
      @driver.ensure_no_such_element(:link, 'Create Batch Locations')
      @driver.ensure_no_such_element(:link, 'Edit')
    end

    @driver.click_and_wait_until_gone(:link, 'View')

    assert(20) do
      @driver.ensure_no_such_element(:link, 'Edit')
    end
  end

  it 'lists the location in different repositories' do
    repo = create(:repo)

    @driver.logout.login($admin)

    assert(5) do
      @driver.navigate.refresh
      @driver.select_repo(repo.repo_code)
    end

    @driver.find_element(:link, 'Browse').click
    @driver.wait_for_dropdown
    @driver.click_and_wait_until_gone(:link, 'Locations')

    expect do
      @driver.find_paginated_element(xpath: "//tr[.//*[contains(text(), '329 W. 81st St, 5, 5A [Box XYZ: XYZ0001]')]]")
    end.not_to raise_error
  end

  describe 'Location batch' do
    before(:all) do
      @driver.logout.login(@manager_user)
    end

    it 'displays error messages upon invalid batch' do
      @driver.get($frontend)

      @driver.find_element(:link, 'Browse').click
      @driver.wait_for_dropdown
      @driver.click_and_wait_until_gone(:link, 'Locations')
      @driver.click_and_wait_until_gone(:link, 'Create Batch Locations')

      @driver.click_and_wait_until_gone(css: 'form#new_location_batch .btn-primary')

      # we don't want certain values in the form
      assert(5) { @driver.ensure_no_such_element(:id, 'location_batch_barcode_') }
      assert(5) { @driver.ensure_no_such_element(:id, 'location_batch_classification_') }
      assert(5) { @driver.ensure_no_such_element(:id, 'location_batch_coordinate_1_label_') }
      assert(5) { @driver.ensure_no_such_element(:id, 'location_batch_coordinate_1_indicator_') }
      assert(5) { @driver.ensure_no_such_element(:id, 'location_batch_coordinate_2_label_') }
      assert(5) { @driver.ensure_no_such_element(:id, 'location_batch_coordinate_2_indicator_') }
      assert(5) { @driver.ensure_no_such_element(:id, 'location_batch_coordinate_3_label_') }
      assert(5) { @driver.ensure_no_such_element(:id, 'location_batch_coordinate_3_indicator_') }

      @driver.find_element_with_text('//div[contains(@class, "error")]', /Building - Property is required but was missing/)
      @driver.find_element_with_text('//div[contains(@class, "error")]', /Coordinate Range 1 - Property is required but was missing/)
    end

    it 'can preview the titles of locations that will be created' do
      @driver.clear_and_send_keys([:id, 'location_batch_building_'], '1978 Awesome Street')
      @driver.clear_and_send_keys([:id, 'location_batch_coordinate_1_range__label_'], 'Room')
      @driver.clear_and_send_keys([:id, 'location_batch_coordinate_1_range__start_'], '1A')
      @driver.clear_and_send_keys([:id, 'location_batch_coordinate_1_range__end_'], '1B')
      @driver.clear_and_send_keys([:id, 'location_batch_coordinate_2_range__label_'], 'Shelf')
      @driver.clear_and_send_keys([:id, 'location_batch_coordinate_2_range__start_'], '1')
      @driver.clear_and_send_keys([:id, 'location_batch_coordinate_2_range__end_'], '4')

      @driver.find_element(css: 'form#new_location_batch .btn.preview-locations').click

      modal = @driver.find_element(:id, 'batchPreviewModal')
      @driver.wait_for_ajax

      @driver.find_element_with_text('//div[@id="batchPreviewModal"]//li', /1978 Awesome Street \[Room: 1A, Shelf: 1\]/)
      @driver.find_element_with_text('//div[@id="batchPreviewModal"]//li', /1978 Awesome Street \[Room: 1A, Shelf: 2\]/)
      @driver.find_element_with_text('//div[@id="batchPreviewModal"]//li', /1978 Awesome Street \[Room: 1A, Shelf: 3\]/)
      @driver.find_element_with_text('//div[@id="batchPreviewModal"]//li', /1978 Awesome Street \[Room: 1A, Shelf: 4\]/)
      @driver.find_element_with_text('//div[@id="batchPreviewModal"]//li', /1978 Awesome Street \[Room: 1B, Shelf: 1\]/)
      @driver.find_element_with_text('//div[@id="batchPreviewModal"]//li', /1978 Awesome Street \[Room: 1B, Shelf: 2\]/)
      @driver.find_element_with_text('//div[@id="batchPreviewModal"]//li', /1978 Awesome Street \[Room: 1B, Shelf: 3\]/)
      @driver.find_element_with_text('//div[@id="batchPreviewModal"]//li', /1978 Awesome Street \[Room: 1B, Shelf: 4\]/)

      @driver.click_and_wait_until_gone(:css, '.modal-footer button')
    end

    it 'creates all the locations for the range' do
      @driver.click_and_wait_until_gone(css: 'form#new_location_batch .btn-primary')

      @driver.find_element_with_text('//div[contains(@class, "alert-success")]', /8 Locations Created/)

      run_index_round
      @driver.navigate.refresh

      @driver.clear_and_send_keys([:css, '.sidebar input.text-filter-field'], '1978*')
      @driver.click_and_wait_until_gone(:css, '.sidebar input.text-filter-field + div button')

      @driver.find_element_with_text('//td', /1978 Awesome Street \[Room: 1A, Shelf: 1\]/)
      @driver.find_element_with_text('//td', /1978 Awesome Street \[Room: 1A, Shelf: 2\]/)
      @driver.find_element_with_text('//td', /1978 Awesome Street \[Room: 1A, Shelf: 3\]/)
      @driver.find_element_with_text('//td', /1978 Awesome Street \[Room: 1A, Shelf: 4\]/)
      @driver.find_element_with_text('//td', /1978 Awesome Street \[Room: 1B, Shelf: 1\]/)
      @driver.find_element_with_text('//td', /1978 Awesome Street \[Room: 1B, Shelf: 2\]/)
      @driver.find_element_with_text('//td', /1978 Awesome Street \[Room: 1B, Shelf: 3\]/)
      @driver.find_element_with_text('//td', /1978 Awesome Street \[Room: 1B, Shelf: 4\]/)
    end

    it 'can edit locations in batch' do
      @driver.logout.login($admin)

      @driver.find_element(:link, 'Browse').click
      @driver.click_and_wait_until_gone(:link, 'Locations')

      @driver.clear_and_send_keys([:css, '.sidebar input.text-filter-field'], '1978*')
      @driver.click_and_wait_until_gone(:css, '.sidebar input.text-filter-field + div button')

      (0..7).each do |i|
        @driver.execute_script("$($('.multiselect-column input').get(#{i})).click()")
      end

      @driver.find_element(:css, '.record-toolbar .btn.multiselect-enabled.edit-batch').click
      @driver.find_element(:css, '#confirmChangesModal #confirmButton').click

      @driver.clear_and_send_keys([:id, 'location_batch_floor_'], '6th')
      @driver.clear_and_send_keys([:id, 'location_batch_room_'], 'Studio 5')
      @driver.clear_and_send_keys([:id, 'location_batch_area_'], 'The corner')

      @driver.click_and_wait_until_gone(css: 'form#new_location_batch .btn-primary')
      @driver.find_element_with_text('//div[contains(@class, "alert-success")]', /8 Locations Updated/)
      run_index_round
      @driver.navigate.refresh
      @driver.clear_and_send_keys([:css, '.sidebar input.text-filter-field'], '1978*')
      @driver.click_and_wait_until_gone(:css, '.sidebar input.text-filter-field + div button')

      @driver.find_element_with_text('//td', /1978 Awesome Street, 6th, Studio 5, The corner \[Room: 1A, Shelf: 1\]/)
      @driver.find_element_with_text('//td', /1978 Awesome Street, 6th, Studio 5, The corner \[Room: 1A, Shelf: 2\]/)
      @driver.find_element_with_text('//td', /1978 Awesome Street, 6th, Studio 5, The corner \[Room: 1A, Shelf: 3\]/)
      @driver.find_element_with_text('//td', /1978 Awesome Street, 6th, Studio 5, The corner \[Room: 1A, Shelf: 4\]/)
      @driver.find_element_with_text('//td', /1978 Awesome Street, 6th, Studio 5, The corner \[Room: 1B, Shelf: 1\]/)
      @driver.find_element_with_text('//td', /1978 Awesome Street, 6th, Studio 5, The corner \[Room: 1B, Shelf: 2\]/)
      @driver.find_element_with_text('//td', /1978 Awesome Street, 6th, Studio 5, The corner \[Room: 1B, Shelf: 3\]/)
      @driver.find_element_with_text('//td', /1978 Awesome Street, 6th, Studio 5, The corner \[Room: 1B, Shelf: 4\]/)
    end

    it 'can create locations with +1 stickyness' do
      @driver.navigate.to("#{$frontend}/locations")
      @driver.click_and_wait_until_gone(:link, 'Create Batch Locations')

      @driver.clear_and_send_keys([:id, 'location_batch_building_'], '555 Fake Street')
      @driver.clear_and_send_keys([:id, 'location_batch_floor_'], '2nd')
      @driver.clear_and_send_keys([:id, 'location_batch_room_'], '201')
      @driver.clear_and_send_keys([:id, 'location_batch_area_'], 'Corner')
      @driver.clear_and_send_keys([:id, 'location_batch_coordinate_1_range__label_'], 'Room')
      @driver.clear_and_send_keys([:id, 'location_batch_coordinate_1_range__start_'], '1A')
      @driver.clear_and_send_keys([:id, 'location_batch_coordinate_1_range__end_'], '1B')
      @driver.clear_and_send_keys([:id, 'location_batch_coordinate_2_range__label_'], 'Shelf')
      @driver.clear_and_send_keys([:id, 'location_batch_coordinate_2_range__start_'], '1')
      @driver.clear_and_send_keys([:id, 'location_batch_coordinate_2_range__end_'], '4')

      @driver.click_and_wait_until_gone(css: 'form#new_location_batch .createPlusOneBtn')

      @driver.find_element_with_text('//div[contains(@class, "alert-success")]', /Locations Created/)
      # these are sticky
      assert(5) { expect(@driver.find_element(:id, 'location_batch_building_').attribute('value')).to eq('555 Fake Street') }

      assert(5) { expect(@driver.find_element(:id,  'location_batch_floor_').attribute('value')).to eq('2nd') }
      assert(5) { expect(@driver.find_element(:id,  'location_batch_room_').attribute('value')).to eq('201') }
      assert(5) { expect(@driver.find_element(:id, 'location_batch_area_').attribute('value')).to eq('Corner') }
    end

    it 'correctly sorts locations in the browse list' do
      @driver.get($frontend)

      @driver.find_element(:link, 'Browse').click
      @driver.wait_for_dropdown
      @driver.click_and_wait_until_gone(:link, 'Locations')

      @driver.find_elements(:css, 'th')[1].click

      table_rows = @driver.find_elements(:css, "tr")
      table_rows.shift

      table_rows_location_text = []
      table_rows.each do |row|
        table_rows_location_text << row.find_elements(:css, "td")[1].text
      end

      table_rows_location_text_sorted = table_rows_location_text.sort

      ns_idx1 = table_rows_location_text.index { |i| i =~ /329 W\. 81st St/ }
      ns_idx2 = table_rows_location_text.index { |i| i =~ /1978 Awesome Street/ }
      ss_idx1 = table_rows_location_text_sorted.index { |i| i =~ /329 W\. 81st St/ }
      ss_idx2 = table_rows_location_text_sorted.index { |i| i =~ /1978 Awesome Street/ }

      expect(ns_idx1).to be < ns_idx2
      expect(ss_idx1).to be > ss_idx2
      expect(table_rows_location_text).not_to eq(table_rows_location_text_sorted)
    end
  end
end
