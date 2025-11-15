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

  # row_values [Array<String>] The expected row values in the sorted results
  # sort_params [Hash{Symbol=>String}] The sort parameters to expect:
  #   { heading: String, sort_key: String, direction: String }
  # is_initial_sort [Boolean] Whether this is the initial sort
  def expect_sorted_results(row_values, sort_params, is_initial_sort = false)
    heading, sort_key, direction = sort_params.values_at(:heading, :sort_key, :direction)
    opposite_direction = opposite_sort_direction(direction)

    within '#tabledSearchResults' do
      aggregate_failures "sorted results for #{heading} #{direction}" do
        verify_sort_column_attributes(heading, sort_key, direction, opposite_direction, is_initial_sort)
        verify_primary_column_values_by_row(row_values, primary_column_class_name)
      end
    end

    verify_url_params(sort_key, direction) unless is_initial_sort
  end

  it 'toggles between ascending and descending sort on repeated clicks per sortable column' do
    verify_initial_sort_state

    column_headers.each_with_index do |(heading, sort_key), index|
      verify_column_sort_cycles(heading, sort_key, first_column: index.zero?)
    end
  end

  private

  def verify_initial_sort_state
    expect_sorted_results(
      initial_sort,
      { heading: column_headers.key(default_sort_key), sort_key: default_sort_key, direction: :asc },
      true
    )
  end

  # @param heading [String] The column heading text
  # @param sort_key [String] The sort parameter key
  # @param first_column [Boolean] Whether this is the first column being tested
  def verify_column_sort_cycles(heading, sort_key, first_column:)
    sort_order = sort_cycle_for_column(sort_key, first_column: first_column)

    sort_order.each do |direction|
      click_column_heading(heading)
      expect_sorted_results(
        sort_expectations.dig(sort_key, direction),
        { heading: heading, sort_key: sort_key, direction: direction }
      )
    end
  end

  # @param sort_key [String] The sort parameter key
  # @param first_column [Boolean] Whether this is the first column
  def sort_cycle_for_column(sort_key, first_column:)
    if first_column && is_default_sort_key?(sort_key)
      [:desc, :asc, :desc]
    else
      [:asc, :desc, :asc]
    end
  end

  # @param sort_key [String] The sort parameter key to check
  def is_default_sort_key?(sort_key)
    respond_to?(:default_sort_key) && sort_key == default_sort_key
  end

  def primary_column_class_name
    respond_to?(:primary_column_class) ? primary_column_class : 'title'
  end

  # @param direction [Symbol] The current sort direction (:asc or :desc)
  def opposite_sort_direction(direction)
    direction == :asc ? :desc : :asc
  end

  # @param heading [String] The column heading text
  # @param sort_key [String] The sort parameter key
  # @param current_direction [Symbol] The current sort direction
  # @param next_direction [Symbol] The direction that clicking will toggle to
  # @param is_initial_sort [Boolean] Whether this is the initial page load sort
  def verify_sort_column_attributes(heading, sort_key, current_direction, next_direction, is_initial_sort)
    return if is_initial_sort && respond_to?(:default_sort_key) && default_sort_key == 'score'

    expect(page).to have_css(
      "thead th.sortable.sort-#{current_direction} a[href*='#{sort_key}+#{next_direction}']",
      text: heading
    )
  end

  # @param row_values [Array<String>] The expected values for each row
  # @param col_class [String] The CSS class of the column to verify
  def verify_primary_column_values_by_row(row_values, col_class)
    row_values.each.with_index(1) do |value, row_number|
      expect(page).to have_css("tbody > tr:nth-child(#{row_number}) > td.#{col_class}", text: value)
    end
  end

  # @param sort_key [String] The sort parameter key
  # @param direction [Symbol] The sort direction
  def verify_url_params(sort_key, direction)
    return unless should_verify_url?

    expect(page).to have_current_path(/sort=#{sort_key}\+#{direction}/)
  end

  def should_verify_url?
    respond_to?(:sorting_in_url) && sorting_in_url
  end
end
