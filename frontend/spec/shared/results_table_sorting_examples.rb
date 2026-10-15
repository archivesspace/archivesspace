# frozen_string_literal: true


# Required lets in the including context:
# - initial_sort [Array<String>] The expected titles order on initial render (first N rows)
# - column_headers [Hash{String=>String}] Mapping of column headers to their sort keys
# - primary_sort_expectations [Hash{String=>Hash{Symbol=>Array<String>}}] Expected titles order per
#   sort key and direction for PRIMARY sort testing, e.g. {
#     'identifier' => { asc: ['1', '2'], desc: ['2', '1'] },
#     'title_sort' => { asc: ['A', 'B'], desc: ['B', 'A'] }
#   }
# - default_sort_key [String] The sort key that the page uses by default on initial load.
#   When the first column matches this key, the test expects desc→asc→desc instead of
#   asc→desc→asc, because the page is already sorted by this column in ascending order on page load.
#
# Optional lets:
# - primary_column_class [String] CSS class for the primary sortable column (default: 'title')
# - is_modal [Boolean] Whether the results table is in a modal context (default: false).
#   When true, URL parameter verification is skipped.


# sorting by the columns and the sort dropdown menus
RSpec.shared_examples 'results table sorting' do
  include_context 'results table sorting helpers'

  context 'sortable columns' do
    it 'toggle between ascending and descending sort on repeated clicks' do
      verify_sortable_columns_behavior
    end
  end

  context 'primary sort dropdown menu' do
    it 'provides ascending and descending sort per sortable column' do
      verify_primary_sort_menu_behavior
    end
  end

  context 'secondary sort dropdown menu' do
    before do
      setup_secondary_sort_environment
    end

    it 'provides a second sort layer given some primary sort keys' do
      verify_secondary_sort_menu_behavior
    end
  end
end


# the initial state of a table sorted by default_sort_key on page load
RSpec.shared_examples 'results table initial sort' do
  include_context 'results table sorting helpers'

  it 'has the correct initial sort state' do
    expect_sorted_results(
      initial_sort,
      { heading: column_headers.key(default_sort_key), sort_key: default_sort_key, direction: :asc },
      is_initial_sort: true
    )
  end
end
