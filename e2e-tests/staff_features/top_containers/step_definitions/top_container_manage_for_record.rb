# frozen_string_literal: true

def open_top_containers_panel_with_retry
  retries = 0
  loop do
    within '#other-dropdown' do
      find('.dropdown-toggle').click
    end
    find('.access-top-containers-btn').click
    wait_for_ajax

    break if page.has_css?('#accessTopContainersModal #bulk_operation_results tbody tr', wait: 5)

    page.execute_script("$('#accessTopContainersModal').modal('hide')")
    wait_for_ajax
    sleep 1

    retries += 1
    raise 'Top containers did not appear in the management panel after multiple attempts' if retries >= 4

    sleep 2
  end
end

When 'the archivist manages top containers for the resource' do
  open_top_containers_panel_with_retry
end

Then 'all top containers linked to that resource are displayed' do
  within '#accessTopContainersModal' do
    expect(page).to have_css('#bulk_operation_results tbody tr', text: @uuid)
  end
end

When "the archivist views a top container's details" do
  within '#accessTopContainersModal' do
    find('.inline-tc-view-btn', match: :first).click
  end
  wait_for_ajax
end

Then 'the top container information is displayed in full' do
  within '#accessTopContainerSubModal' do
    expect(page).to have_text @uuid
  end
end

When 'the archivist updates the barcode of a top container' do
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

Then 'the archivist remains within the resource context' do
  expect(current_url).to include "/resources/#{@resource_id}"
end

Then 'the updated barcode is reflected in the top container management view' do
  within '#accessTopContainersModal' do
    expect(page).to have_css('#bulk_operation_results tbody td.top-container-barcode', text: @new_barcode)
  end
end

When 'the archivist applies a bulk barcode update to the selected top containers' do
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
end

Then 'the bulk barcode update is confirmed' do
  within '#bulkActionBarcodeRapidEntryModal' do
    expect(page).to have_css('.alert-success')
  end
end

Then 'the affected top containers reflect the updated barcode' do
  visit "#{STAFF_URL}/top_containers/#{@top_container_id}/edit"
  expect(page).to have_field('Barcode', with: @new_barcode)
end

When 'the archivist opens the top container management panel for the accession' do
  expect(page).to have_selector('h2', visible: true, text: 'Accession')
  wait_for_ajax
  open_top_containers_panel_with_retry
end

Then 'all top containers linked to that accession are displayed' do
  within '#accessTopContainersModal' do
    expect(page).to have_css('#bulk_operation_results tbody tr', text: @uuid)
  end
end
