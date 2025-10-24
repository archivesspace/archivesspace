# frozen_string_literal: true

# Shared examples for verifying column sorting behavior in search results tables.
#
# Requires:
# - let(:browse_path) - the path to the browse page (e.g., '/collection_management')
# - let(:sortable_column_label) - the text label of a sortable column (e.g., 'Processing Priority')

RSpec.shared_examples 'column sorting cycles through asc and desc' do
  it 'cycles between ascending and descending on repeated clicks' do
    visit browse_path

    # Wait for table to load
    expect(page).to have_css('#tabledSearchResults')

    # Find the sortable column header and click it
    within('#tabledSearchResults thead') do
      click_link sortable_column_label
    end

    # First click: sort ascending
    expect(page).to have_css('th.sort-asc', text: sortable_column_label, wait: 5)

    # Second click: sort descending
    within('#tabledSearchResults thead') do
      click_link sortable_column_label
    end
    expect(page).to have_css('th.sort-desc', text: sortable_column_label, wait: 5)

    # Third click: should cycle back to ascending (not reset to default)
    within('#tabledSearchResults thead') do
      click_link sortable_column_label
    end
    expect(page).to have_css('th.sort-asc', text: sortable_column_label, wait: 5)

    # Fourth click: back to descending
    within('#tabledSearchResults thead') do
      click_link sortable_column_label
    end
    expect(page).to have_css('th.sort-desc', text: sortable_column_label, wait: 5)
  end
end
