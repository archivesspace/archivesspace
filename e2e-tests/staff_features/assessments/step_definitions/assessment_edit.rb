# frozen_string_literal: true

When 'the user filters by the text {string}' do |string|
  within '.modal-content' do
    submit_listing_filter(string)
  end
end
