# frozen_string_literal: true

# Shared examples for verifying that boolean search result columns
# render the expected values.
#
# Intended to be used alongside the "sortable results table" sorting
# examples in specs that use the 'results table setup' context.
#
# Required lets in the including context:
# - initial_sort [Array<String>] The expected primary values for the first N
#   rows. This array's length determines how many rows will be checked.
# - boolean_column_expectations [Hash{String=>Array<String>}]
#   A mapping from the column's CSS class (typically the sort key / field
#   name, e.g. 'is_user', 'assessment_review_required') to the expected
#   displayed text for each checked row, in row order. For example:
#
#     let(:boolean_column_expectations) do
#       {
#         'is_user' => %w[False False],
#         'assessment_review_required' => %w[False True],
#       }
#     end
RSpec.shared_examples 'results table boolean columns' do
  it 'renders boolean browse columns for both true and false values' do
    row_count = initial_sort.length

    within '#tabledSearchResults tbody' do
      (1..row_count).each do |row_index|
        within "tr:nth-child(#{row_index})" do
          boolean_column_expectations.each do |column_class, expected_values|
            expected_text = expected_values.fetch(row_index - 1)

            expect(page).to have_css("td.#{column_class}", text: expected_text)
          end
        end
      end
    end
  end
end
