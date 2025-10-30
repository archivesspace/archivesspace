# frozen_string_literal: true

# Shared examples for verifying column sorting behavior in search results tables.
#
# Required lets in the including context:
# - initial_sort [Array<String>] The expected titles order on initial render (first N rows).
# - column_headers [Hash{String=>String}] Mapping of column headers to sort keys
#   used by the UI logic (e.g., { 'Accession Date' => 'accession_date' }).
# - sort_expectations [Hash{String=>Hash{Symbol=>Array<String>}}] Expected titles order per
#   sort key and direction, e.g. {
#     'identifier' => { asc: ['A', 'B'], desc: ['B', 'A'] },
#     'title_sort' => { asc: ['A', 'B'], desc: ['B', 'A'] }
#   }.
#
# Example usage:
#
#   let(:initial_sort) { [record_1_title, record_2_title] }
#   let(:column_headers) do
#     {
#       'Accession Date' => 'accession_date',
#       'Identifier'     => 'identifier',
#       'Title'          => 'title_sort'
#     }
#   end
#   let(:sort_expectations) do
#     {
#       'accession_date' => { asc: [record_2_title, record_1_title], desc: [record_1_title, record_2_title] },
#       'identifier'     => { asc: [record_1_title, record_2_title], desc: [record_2_title, record_1_title] },
#       'title_sort'     => { asc: [record_1_title, record_2_title], desc: [record_2_title, record_1_title] }
#     }
#   end
#   it_behaves_like 'sortable results table'
RSpec.shared_examples 'sortable results table' do
  def click_column_header(heading)
    within '#tabledSearchResults thead' do
      click_link heading
    end
  end

  def expect_sorted_results(titles)
    aggregate_failures "sorted results" do
      titles.each_with_index do |title, index|
        within '#tabledSearchResults' do
          expect(page).to have_css("tbody > tr:nth-child(#{index + 1}) > td.title", text: title)
        end
      end
    end
  end

  it 'toggles between ascending and descending sort on repeated clicks per sortable column' do
    expect_sorted_results(initial_sort)

    column_headers.each do |heading, sort_key|
      click_column_header(heading)
      expect_sorted_results(sort_expectations.fetch(sort_key).fetch(:asc))

      click_column_header(heading)
      expect_sorted_results(sort_expectations.fetch(sort_key).fetch(:desc))

      click_column_header(heading)
      expect_sorted_results(sort_expectations.fetch(sort_key).fetch(:asc))
    end
  end
end
