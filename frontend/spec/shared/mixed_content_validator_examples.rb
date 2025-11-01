# frozen_string_literal: true

# Shared examples for validating mixed content in title fields across record types.
#
# Requires the including spec to define:
# - let(:edit_path) - String path to the edit page for the record
# - let(:input_field_id) - String field id used by fill_in (e.g., 'resource_title_')
RSpec.shared_examples 'validating mixed content' do
  def submit_and_expect(title_value:, expectation_text:)
    fill_in input_field_id, with: title_value
    find('button', text: 'Save', match: :first).click

    aggregate_failures do
      expect(page).to have_css('#form_messages', text: expectation_text)
      expect(page).to have_css("##{input_field_id}", text: title_value)
    end
  end

  let(:now) { Time.now.to_i }
  let(:malformed_attr_1) { "<title render='italic>Invalid attribute 1 #{now}</title>" }
  let(:malformed_attr_2) { "<title render=\"italic>Invalid attribute 2 #{now}</title>" }
  let(:malformed_tag_1) { "<title>Invalid tag 1 #{now}<title>" }
  let(:malformed_tag_2) { "<title Invalid tag 2 #{now}</title>" }
  let(:valid_title) { "<title>Valid Title #{now}</title>" }
  let(:error_message) { 'Title - Invalid EAD markup' }
  let(:success_message) { "Valid Title #{now} updated" }

  it 'validates mixed content in the title' do
    visit edit_path

    [malformed_attr_1, malformed_attr_2, malformed_tag_1, malformed_tag_2].each do |invalid|
      submit_and_expect(title_value: invalid, expectation_text: error_message)
    end

    submit_and_expect(title_value: valid_title, expectation_text: success_message)
  end
end
