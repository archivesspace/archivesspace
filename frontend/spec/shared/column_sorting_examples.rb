# frozen_string_literal: true

# Shared examples for verifying column sorting behavior in search results tables.
#
# Required lets in the including context:
# - initial_sort [Array<String>] The expected titles order on initial render (first N rows)
# - column_headers [Hash{String=>String}] Mapping of column headers to their sort keys
# - sort_expectations [Hash{String=>Hash{Symbol=>Array<String>}}] Expected titles order per
#   sort key and direction, e.g. {
#     'identifier' => { asc: ['1', '2'], desc: ['2', '1'] },
#     'title_sort' => { asc: ['A', 'B'], desc: ['B', 'A'] }
#   }.
#
# Optional lets:
# - primary_column_class [String] CSS class for the primary sortable column (default: 'title')
# - sorting_in_url [Boolean] Whether to verify that sort parameters are reflected in the URL
# - default_sort_key [String] The sort key that the page uses by default on initial load.
#   When the first column matches this key, the test expects desc→asc→desc instead of
#   asc→desc→asc, because the page is already sorted by this column in ascending order on page load.

RSpec.shared_examples 'sortable results table' do
  # heading [String] The column heading to click
  def click_column_heading(heading)
    within '#tabledSearchResults thead' do
      click_link heading
    end
  end

  # values [Array<String>] The expected values in the sorted results
  # sort_params [Hash{Symbol=>String}] The sort parameters to expect:
  #   { heading: String, sort_key: String, direction: String }
  def expect_sorted_results(values, sort_params)
    col_class = respond_to?(:primary_column_class) ? primary_column_class : 'title'
    sort_context = sort_params ? "#{sort_params[:heading]} #{sort_params[:direction]}" : "initial sort"

    aggregate_failures "sorted results for #{sort_context}" do
      values.each_with_index do |value, index|
        within '#tabledSearchResults' do
          expect(page).to have_css("tbody > tr:nth-child(#{index + 1}) > td.#{col_class}", text: value)
        end
      end

      if sort_params && respond_to?(:sorting_in_url) && sorting_in_url
        expect(page).to have_current_path(/sort=#{sort_params[:sort_key]}\+#{sort_params[:direction]}/)
      end
    end
  end

  it 'toggles between ascending and descending sort on repeated clicks per sortable column' do
    expect_sorted_results(initial_sort, nil)

    column_headers.each_with_index do |(heading, sort_key), index|
      this_col_is_first_and_default = index.zero? && respond_to?(:default_sort_key) && sort_key == default_sort_key
      sort_order = this_col_is_first_and_default ? [:desc, :asc, :desc] : [:asc, :desc, :asc]

      sort_order.each do |direction|
        click_column_heading(heading)
        expect_sorted_results(sort_expectations.fetch(sort_key).fetch(direction),
                             { heading: heading, sort_key: sort_key, direction: direction.to_s })
      end
    end
  end
end
