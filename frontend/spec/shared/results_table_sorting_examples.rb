# frozen_string_literal: true

# Shared examples for verifying sorting behavior in search/browse results tables.
#
# Required lets in the including context:
# - initial_sort [Array<String>] The expected titles order on initial render (first N rows)
# - column_headers [Hash{String=>String}] Mapping of column headers to their sort keys
# - sort_expectations [Hash{String=>Hash{Symbol=>Array<String>}}] Expected titles order per
#   sort key and direction, e.g. {
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

RSpec.shared_examples 'results table sorting' do
  # @param heading [String] The column heading to click
  def click_column_heading(heading)
    within '#tabledSearchResults thead' do
      click_link heading
    end
  end

  # @param menu [Symbol] The menu to click (:primary or :secondary)
  # @param heading [String] The column heading to sort by
  # @param direction [Symbol] The sort direction (:asc or :desc)
  def click_sort_menu_option(menu, heading, direction)
    within "#pagination-summary-#{menu}-sort-opts" do
      find('button.dropdown-toggle').click
      find('li.dropdown-submenu', text: heading).hover
      click_link direction_text(direction)
    end
  end

  # @param row_values [Array<String>] The expected row values in the sorted results
  # @param sort_params [Hash{Symbol=>String}] The sort parameters to expect:
  #   { heading: String, sort_key: String, direction: String }
  # @param is_initial_sort [Boolean] Whether this is the initial sort (default: false)
  # @param fail_message [String] A custom failure message to use instead of the default
  def expect_sorted_results(row_values, sort_params, is_initial_sort: false, fail_message: nil)
    heading, sort_key, direction = sort_params.values_at(:heading, :sort_key, :direction)
    opposite_direction = opposite_sort_direction(direction)
    fail_message ||= "sorted results for #{heading} #{direction}"

    aggregate_failures fail_message do
      verify_sort_buttons_text(heading, direction, is_initial_sort: is_initial_sort)
      verify_sort_menu_options(current_primary_heading: heading)

      within '#tabledSearchResults' do
        verify_sort_column_attributes(heading, sort_key, direction, opposite_direction, is_initial_sort: is_initial_sort)
        verify_primary_column_values_by_row(row_values, primary_column_class_name)
      end
    end

    verify_url_params(primary_key: sort_key, primary_dir: direction) unless is_initial_sort
  end

  def verify_primary_sort_menu_behavior
    # Here the directions are iterated over first, then each menu option. The inverse
    # iteration order resulted in Webdriver flakiness, "element not interactable /
    # could not be scrolled into view" errors, when trying to hover to expose the
    # second link for a given menu option.
    [:asc, :desc].each do |direction|
      column_headers.to_a.each do |heading, sort_key|
        click_sort_menu_option(:primary, heading, direction)
        expect_sorted_results(
          sort_expectations.dig(sort_key, direction),
          { heading: heading, sort_key: sort_key, direction: direction }
        )
      end
    end
  end

  def verify_secondary_sort_menu_behavior
    unless respond_to?(:secondary_sort_cases)
      skip 'secondary_sort_cases not defined for this context'
    end

    secondary_sort_cases.each do |test_case|
      primary_key       = test_case.fetch(:primary_key)
      primary_dir       = test_case.fetch(:primary_dir)
      secondary_key     = test_case.fetch(:secondary_key)
      secondary_dir     = test_case.fetch(:secondary_dir)
      primary_heading   = column_headers.key(primary_key)
      secondary_heading = column_headers.key(secondary_key)

      click_sort_menu_option(:primary, primary_heading, primary_dir)
      expect_sorted_results(
        test_case[:expected_after_primary],
        { heading: primary_heading, sort_key: primary_key, direction: primary_dir },
        fail_message: "primary sort within secondary sort test case: #{primary_heading} #{primary_dir}"
      )

      click_sort_menu_option(:secondary, secondary_heading, secondary_dir)
      aggregate_failures "secondary sort: #{primary_heading} #{primary_dir}, then #{secondary_heading} #{secondary_dir}" do
        verify_url_params(primary_key: primary_key, primary_dir: primary_dir, secondary_key: secondary_key, secondary_dir: secondary_dir)
        verify_sort_buttons_text(
          primary_heading, primary_dir,
          secondary_heading: secondary_heading,
          secondary_direction: secondary_dir
        )
        verify_primary_column_values_by_row(
          test_case.fetch(:expected_after_both),
          primary_column_class_name
        )
      end
    end
  end

  def verify_sortable_columns_behavior
    column_headers.each_with_index do |(heading, sort_key), index|
      verify_column_sort_cycles(heading, sort_key, first_column: index.zero?)
    end
  end

  def setup_secondary_sort_environment
    return unless respond_to?(:record_3) && respond_to?(:secondary_sort_cases)

    record_3
    run_index_round
    go_to_results_table
    filter_results_for_comparison if respond_to?(:filter_results) && filter_results
  end

  it 'has the correct initial sort state' do
    verify_initial_sort_state
  end

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

  private

  def verify_initial_sort_state
    # There is no score column
    heading = default_sort_key == 'score' ? 'Relevance' : column_headers.key(default_sort_key)

    expect_sorted_results(
      initial_sort,
      { heading: heading, sort_key: default_sort_key, direction: :asc },
      is_initial_sort: true
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

  # @param primary_heading [String] The primary column heading text
  # @param primary_direction [Symbol] The primary sort direction (:asc or :desc)
  # @param secondary_heading [String] The secondary column heading (default: 'Select')
  # @param secondary_direction [Symbol, nil] The secondary sort direction (default: nil)
  # @param is_initial_sort [Boolean] Whether this is the initial page load sort (default: false)
  # @param fail_message [String] A custom failure message to use instead of the default
  def verify_sort_buttons_text(primary_heading, primary_direction, secondary_heading: 'Select', secondary_direction: nil, is_initial_sort: false, fail_message: nil)
    primary_expected_text = if multi_record_search_initial_sort?(is_initial_sort)
                              'Relevance'
                            else
                              "#{primary_heading} #{direction_text(primary_direction)}"
                            end

    aggregate_failures fail_message || 'sort buttons text' do
      expect(page).to have_css('#pagination-summary-primary-sort-opts > button', text: primary_expected_text)

      # No secondary sort button when sorted by Relevance
      unless primary_expected_text == 'Relevance'
        secondary_expected_text = if secondary_heading == 'Select'
                                    'Select'
                                  else
                                    "#{secondary_heading} #{direction_text(secondary_direction)}"
                                  end
        expect(page).to have_css('#pagination-summary-secondary-sort-opts > button', text: secondary_expected_text)
      end
    end
  end

  # @param current_primary_heading [String, nil] The currently selected primary sort heading
  #   (used to filter it out of secondary menu options). If nil, verifies primary menu only.
  def verify_sort_menu_options(current_primary_heading: nil)
    verify_primary_sort_menu_options(current_primary_heading)

    # No secondary sort menu when sorted by Relevance
    if current_primary_heading && current_primary_heading != 'Relevance'
      verify_secondary_sort_menu_options(current_primary_heading)
    end
  end

  # @param current_primary_heading [String, nil] The currently selected primary sort heading
  def verify_primary_sort_menu_options(current_primary_heading = nil)
    expected_options = ['Created', 'Modified'] + column_headers.keys

    # Relevance only appears in menu when NOT currently sorted by it (it only has descending)
    if default_sort_key == 'score' && current_primary_heading != 'Relevance'
      expected_options << 'Relevance'
    end

    aggregate_failures 'primary sort menu options' do
      actual_options = extract_dropdown_options_via_js('#pagination-summary-primary-sort-opts > .dropdown-menu')
      expect(actual_options).to eq(expected_options)
    end
  end

  # @param current_primary_heading [String] The currently selected primary sort heading
  def verify_secondary_sort_menu_options(current_primary_heading)
    expected_options = ['Created', 'Modified'] + column_headers.keys
    expected_options.delete(current_primary_heading)

    aggregate_failures 'secondary sort menu options' do
      actual_options = extract_dropdown_options_via_js('#pagination-summary-secondary-sort-opts > .dropdown-menu')
      expect(actual_options).to eq(expected_options)
    end
  end

  # @param heading [String] The column heading text
  # @param sort_key [String] The sort parameter key
  # @param current_direction [Symbol] The current sort direction
  # @param next_direction [Symbol] The direction that clicking will toggle to
  # @param is_initial_sort [Boolean] Whether this is the initial page load sort
  def verify_sort_column_attributes(heading, sort_key, current_direction, next_direction, is_initial_sort:)
    # Multi-record search sorts by score on page load, so skip it since there's no score column
    return if multi_record_search_initial_sort?(is_initial_sort)

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

  # @param primary_key [String] The primary sort parameter key
  # @param primary_dir [Symbol] The primary sort direction
  # @param secondary_key [String, nil] The secondary sort parameter key (optional)
  # @param secondary_dir [Symbol, nil] The secondary sort direction (optional)
  def verify_url_params(primary_key:, primary_dir:, secondary_key: nil, secondary_dir: nil)
    return unless should_verify_url?

    primary_sort = "sort=#{primary_key}\\+#{primary_dir}"
    if secondary_key && secondary_dir
      secondary_sort = "%2C\\+#{secondary_key}\\+#{secondary_dir}"
      expect(page).to have_current_path(/#{primary_sort}#{secondary_sort}/)
    else
      expect(page).to have_current_path(/#{primary_sort}/)
    end
  end

  # @param sort_key [String] The sort parameter key
  # @param first_column [Boolean] Whether this is the first column
  # @return [Array<Symbol>] The sort cycle order (e.g., [:desc, :asc, :desc])
  def sort_cycle_for_column(sort_key, first_column:)
    if first_column && is_default_sort_key?(sort_key)
      [:desc, :asc, :desc]
    else
      [:asc, :desc, :asc]
    end
  end

  # @param sort_key [String] The sort parameter key to check
  # @return [Boolean] True if the sort key matches the default sort key
  def is_default_sort_key?(sort_key)
    sort_key == default_sort_key
  end

  # @return [String] The CSS class name for the primary sortable column
  def primary_column_class_name
    respond_to?(:primary_column_class) ? primary_column_class : 'title'
  end

  # @param direction [Symbol] The current sort direction (:asc or :desc)
  # @return [Symbol] The opposite sort direction
  def opposite_sort_direction(direction)
    direction == :asc ? :desc : :asc
  end

  # @param direction [Symbol] The sort direction (:asc or :desc)
  # @return [String] The human-readable direction text ('Ascending' or 'Descending')
  def direction_text(direction)
    direction == :asc ? 'Ascending' : 'Descending'
  end

  # Extracts dropdown option text using JavaScript to avoid StaleElementReferenceError.
  # This executes atomically in the browser, preventing race conditions between
  # element collection and text extraction that occur in slower CI environments.
  #
  # @param menu_selector [String] CSS selector for the dropdown menu container
  # @return [Array<String>] The text content of each dropdown menu option
  def extract_dropdown_options_via_js(menu_selector)
    page.evaluate_script(<<~JS)
      Array.from(document.querySelectorAll('#{menu_selector} .dropdown-item > a'))
        .map(el => el.textContent.trim())
    JS
  end

  # @return [Boolean] True if URL params should be verified
  def should_verify_url?
    is_modal_context = respond_to?(:is_modal) ? is_modal : false
    !is_modal_context
  end

  # @param is_initial_sort [Boolean] Whether this is the initial page load sort
  # @return [Boolean] True if this is initial sort and default key is 'score'
  def multi_record_search_initial_sort?(is_initial_sort)
    is_initial_sort && default_sort_key == 'score'
  end
end
