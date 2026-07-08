# frozen_string_literal: true

Given 'the user is on the {string} background job page' do |string|
  click_on 'Create'
  click_on 'Background Job'
  click_on string
end

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

Then 'the job completes' do
  tries = 0

  loop do
    expect(page).to_not have_text 'This job is next in the queue.'
    expect(page).to have_text 'The job has completed.'

    break
  rescue RSpec::Expectations::ExpectationNotMetError => e
    tries += 1
    sleep 3

    raise e if tries == 5
  end
end
