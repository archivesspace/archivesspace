# frozen_string_literal: true

When 'the user checks {string} in the LCNAF Import form' do |string|
  elements = all(:css, "div[class*='radio']")

  elements.each do |element|
    element.find('input').click if element.text == string
  end
end

When 'the user selects the first Subject from the search results' do
  expect(page).to have_text('Showing results')

  find('#results div.lcnaf-result button', match: :first).click
end
