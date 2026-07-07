# frozen_string_literal: true

Then 'the {string} page is displayed' do |string|
  tries = 0

  loop do
    expect(find('h2').text).to start_with string

    break
  rescue RSpec::Expectations::ExpectationNotMetError => e
    tries += 1
    sleep 3

    raise e if tries == 5
  end
end
