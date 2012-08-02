require "selenium-webdriver"
require "digest"

driver = Selenium::WebDriver.for :firefox
driver.navigate.to "http://localhost:3000"

driver.find_element(:class, 'session-actions').click
driver.find_element(:id, 'user_username').send_keys ENV["USER"]
driver.find_element(:id, 'user_password').send_keys "testuser"
driver.find_element(:id, 'login').click

wait = Selenium::WebDriver::Wait.new(:timeout => 10)
wait.until { driver.find_element(:class => "user-label").displayed? }

driver.find_element(:css, '.repository-container .btn').click

# typo :)
driver.find_element(:link, "Create a Respository").click

wait.until { driver.find_element(:id => "repository_repo_id").displayed? }

test_repo_name = "Test repository - #{Time.now}"
driver.find_element(:id => "repository_repo_id").send_keys test_repo_name
driver.find_element(:id => "repository_description").send_keys "Nothing much to see here.  Just a fake repository with Selenium."

driver.find_element(:css => "form#new_repository input[type='submit']").click

# without this sleep sometimes the new repo would not yet be in the list -jj
sleep(1)

wait.until { driver.find_element(:css, '.repository-container .btn') }

driver.find_element(:css, '.repository-container .btn').click

wait.until { driver.find_element(:link, test_repo_name).displayed? }
driver.find_element(:link, test_repo_name).click

sleep(1)

driver.find_element(:link, "Create").click
driver.find_element(:link, "Accession").click

driver.find_element(:id => "accession_title").send_keys "Accession title"
driver.find_element(:id => "accession_accession_id_0").send_keys Digest::MD5.hexdigest("#{Time.now}")

driver.find_element(:css => "button[type='submit']").click

wait.until { driver.find_element(:link, 'Edit Accession').displayed? }
driver.find_element(:link, 'Edit Accession').click

driver.find_element(:id => 'accession_content_description').send_keys "Here is a description of this accession."
driver.find_element(:id => 'accession_condition_description').send_keys "Here we note the condition of this accession."

# note - the form is called 'new_accession' even though this is an edit form -jj
driver.find_element(:css => "form#new_accession button[type='submit']").click

#driver.quit
