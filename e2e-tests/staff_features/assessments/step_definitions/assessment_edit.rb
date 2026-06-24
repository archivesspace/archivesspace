# frozen_string_literal: true

When 'the user filters by the text {string}' do |string|
  fill_in 'Filter by text', with: string

  find('#filter-text').send_keys(:enter)

  wait_for_ajax
end
