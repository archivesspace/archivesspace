# frozen_string_literal: true

# Shared examples for the initial state of a results table that is sorted by relevance on page load
# (default_sort_key 'score'), used instead of 'results table initial sort' together with
# 'results table sorting' (see results_table_sorting_examples.rb).
#
# Records matching the search equally well have no dependable relevance order: Solr boosts each record
# type by how rare it is in the whole index (the bq params in solrconfig.xml), which depends on the
# records of other specs. So the initial_sort titles are expected as the first rows, in any order.
RSpec.shared_examples 'results table initial relevance sort' do
  include_context 'results table sorting helpers'

  it 'has the correct initial sort state' do
    aggregate_failures 'initial relevance sort' do
      # Sorting by relevance has no direction and no secondary sort
      expect(page).to have_css('#pagination-summary-primary-sort-opts > button', text: 'Relevance')
      verify_sort_menu_options(current_primary_heading: 'Relevance')

      # There is no score column, so there are no sort column attributes to verify
      within '#tabledSearchResults' do
        initial_sort.each do |title|
          expect(page).to have_css("tbody > tr:nth-child(-n+#{initial_sort.size}) > td.#{primary_column_class_name}", text: title)
        end
      end
    end
  end
end
