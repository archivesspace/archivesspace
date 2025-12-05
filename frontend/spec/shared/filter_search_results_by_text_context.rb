# frozen_string_literal: true

RSpec.shared_context 'filter search results by text' do
  def filter_search_results_by_text(text)
    fill_in 'filter-text', with: text
    click_on 'Filter by text'
  end
end
