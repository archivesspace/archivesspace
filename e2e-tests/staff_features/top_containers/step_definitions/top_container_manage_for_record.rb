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
  retries = 0
  loop do
    expect(page).to have_selector('h2', visible: true, wait: 15)
    expect(page).to have_css('.access-top-containers-btn[data-tc-initialized]', visible: :all, wait: 10)
    wait_for_ajax

    if find('.access-top-containers-btn', visible: :all).disabled?
      retries += 1
      raise 'Top containers button never became enabled after multiple attempts' if retries >= 10

      sleep 3
      page.evaluate_script('window.location.reload()')
      sleep 0.5
      next
    end

    within '#other-dropdown' do
      find('.dropdown-toggle').click
    end
    sleep 0.3
    find('.access-top-containers-btn').click
    wait_for_ajax
    break
  end
end
