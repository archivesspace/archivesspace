# frozen_string_literal: true

Given 'a Repository has been created' do
  visit "#{STAFF_URL}/repositories/new"

  fill_in 'Repository Short Name', with: "repository_test_#{@uuid}"
  fill_in 'Repository Name', with: "Repository Test #{@uuid}"

  click_on 'Save'

  expect(find('.alert').text).to eq 'Repository Created'

  url_parts = current_url.split('repositories').pop.split('/')
  @repository_id = url_parts.pop
end

When 'the user filters by text with the Repository name' do
  fill_in 'Filter by text', with: "repository_test_#{@uuid}"

  find('#filter-text').send_keys(:enter)

  rows = []
  checks = 0

  while checks < 5
    checks += 1

    begin
      rows = all('tr', text: @uuid)
    rescue Selenium::WebDriver::Error::JavascriptError
      sleep 1
    end

    break if rows.length == 1
  end
end

Then 'the Repository view page is displayed' do
  expect(current_url).to eq "#{STAFF_URL}/repositories/#{@repository_id}"
end

Then 'the Repository is in the search results' do
  expect(page).to have_css('tr', text: @uuid)
end

Given 'two Repositories have been created with a common keyword in their title' do
  @shared_repository_uuid = SecureRandom.uuid
  @repository_a_uuid = SecureRandom.uuid
  @repository_b_uuid = SecureRandom.uuid

  visit "#{STAFF_URL}/repositories/new"
  fill_in 'Repository Short Name', with: "repository_test_a_#{@repository_a_uuid}_#{@shared_repository_uuid}"
  fill_in 'Repository Name', with: "Repository Test A #{@repository_a_uuid} #{@shared_repository_uuid}"
  click_on 'Save'

  uri_parts = current_url.split('/')
  uri_parts.pop
  @repository_first_id = uri_parts.pop

  visit "#{STAFF_URL}/repositories/new"
  fill_in 'Repository Short Name', with: "repository_test_b_#{@repository_b_uuid}_#{@shared_repository_uuid}"
  fill_in 'Repository Name', with: "Repository Test B #{@repository_b_uuid} #{@shared_repository_uuid}x"
  click_on 'Save'
  uri_parts = current_url.split('/')
  uri_parts.pop
  @repository_second_id = uri_parts.pop
end

Given 'the two Repositories are displayed sorted by ascending title in the searh results' do
  visit "#{STAFF_URL}/repositories"

  fill_in 'filter-text', with: @shared_repository_uuid

  within '.search-filter' do
    find('button').click
  end

  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[0]).to have_text @repository_a_uuid
  expect(search_result_rows[1]).to have_text @repository_b_uuid
end

Then 'the two Repositories are displayed sorted by ascending title' do
  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[0]).to have_text @repository_a_uuid
  expect(search_result_rows[1]).to have_text @repository_b_uuid
end
