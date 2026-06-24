# frozen_string_literal: true

Then 'the top container appears linked in the modal' do
  within '#accessTopContainersModal' do
    expect(page).to have_css('#bulk_operation_results tbody tr', text: @uuid)
  end
end

When "the user views a top container's details" do
  within '#accessTopContainersModal' do
    find('.inline-tc-view-btn', match: :first).click
  end
  wait_for_ajax
end

When 'the user updates the barcode of a top container' do
  @new_barcode = SecureRandom.uuid
  within '#accessTopContainersModal' do
    find('.inline-tc-edit-btn', match: :first).click
  end
  wait_for_ajax
  within '#accessTopContainerSubModal' do
    fill_in 'Barcode', with: @new_barcode
    click_on 'Save Top Container'
  end
  wait_for_ajax
end

Then 'the updated barcode is reflected in the top container management view' do
  within '#accessTopContainersModal' do
    expect(page).to have_css('#bulk_operation_results tbody td.top-container-barcode', text: @new_barcode)
  end
end

When 'the user applies a bulk barcode update to the selected top containers' do
  @new_barcode = SecureRandom.uuid
  within '#accessTopContainersModal #bulk_operation_results tbody' do
    find('input[type="checkbox"]', match: :first).click
  end
  within '#accessTopContainersModal' do
    find('button', text: 'Bulk Operations', match: :first).click
  end
  find('#showBulkActionRapidBarcodeEntry').click
  wait_for_ajax
  within '#bulkActionBarcodeRapidEntryModal' do
    find('input[type="text"]').fill_in with: @new_barcode
    click_on 'Update 1 records'
  end
  wait_for_ajax
  within '#bulkActionBarcodeRapidEntryModal' do
    expect(page).to have_css('.alert-success')
  end
end

Then 'the affected top containers reflect the updated barcode' do
  visit "#{STAFF_URL}/top_containers/#{@top_container_id}/edit"
  expect(page).to have_field('Barcode', with: @new_barcode)
end

When 'the user opens the top container management panel' do
  button = '.access-top-containers-btn'

  10.times do
    expect(page).to have_selector('h2', visible: true, wait: 15)
    expect(page).to have_css("#{button}[data-tc-initialized]", visible: :all, wait: 10)
    wait_for_ajax

    # The button can only enable after a reload re-runs the indexed count query,
    # so check the current page immediately (wait: 0) rather than blocking here.
    break unless page.has_css?("#{button}:disabled", visible: :all)

    sleep 4
    page.refresh
  end

  raise 'Top containers button never became enabled after multiple attempts' if page.has_css?("#{button}:disabled", visible: :all)

  within '#other-dropdown' do
    find('.dropdown-toggle').click
  end

  find(button).click
  wait_for_ajax
end
