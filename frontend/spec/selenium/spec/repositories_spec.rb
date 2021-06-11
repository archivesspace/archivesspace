# frozen_string_literal: true

require_relative '../spec_helper'

describe 'Repositories' do
  before(:all) do
    @test_repo_code_1 = "test1#{Time.now.to_i}_#{$$}"
    @test_repo_name_1 = "test repository 1 - #{Time.now.utc}"
    @test_repo_code_2 = "test2#{Time.now.to_i}_#{$$}"
    @test_repo_name_2 = "test repository 2 - #{Time.now.utc}"

    @driver = Driver.get.login($admin)
  end

  after(:all) do
    @driver ? @driver.quit : next
  end

  it 'flags errors when creating a repository with missing fields' do
    @driver.find_element(:link, 'System').click
    @driver.click_and_wait_until_gone(:link, 'Manage Repositories')
    @driver.click_and_wait_until_gone(:link, 'Create Repository')
    @driver.clear_and_send_keys([:id, 'repository_repository__name_'], 'missing repo code')
    @driver.click_and_wait_until_gone(css: "form#new_repository button[type='submit']")

    assert(5) { expect(@driver.find_element(css: 'div.alert.alert-danger').text).to eq('Repository Short Name - Property is required but was missing') }
    # make sure we did not lose the OAI settings list
    expect(@driver.find_elements(:css, "#oai_fields input").length).to eq 12
  end

  it 'can create a repository' do
    @driver.clear_and_send_keys([:id, 'repository_repository__repo_code_'], @test_repo_code_1)
    @driver.clear_and_send_keys([:id, 'repository_repository__name_'], @test_repo_name_1)
    @driver.click_and_wait_until_gone(css: "form#new_repository button[type='submit']")
  end

  it 'can add telephone numbers' do
    @driver.click_and_wait_until_gone(:link, 'Edit')

    @driver.find_element_with_text('//button', /Add Telephone Number/).click

    @driver.clear_and_send_keys([:id, 'repository_agent_representation__agent_contacts__0__telephones__0__number_'], '555-5555')
    @driver.clear_and_send_keys([:id, 'repository_agent_representation__agent_contacts__0__telephones__0__ext_'], '66')

    @driver.find_element_with_text('//button', /Add Telephone Number/).click

    @driver.clear_and_send_keys([:id, 'repository_agent_representation__agent_contacts__0__telephones__1__number_'], '999-9999')

    @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")
    @driver.find_element_with_text('//div[contains(@class, "alert-success")]', /Repository Saved/)

    assert(5) do
      expect(@driver.find_element(id: 'repository_agent_representation__agent_contacts__0__telephones__0_').text).to match(/555\-5555/)
    end

    assert(5) do
      expect(@driver.find_element(id: 'repository_agent_representation__agent_contacts__0__telephones__0_').text).to match(/66/)
    end

    assert(5) do
      expect(@driver.find_element(id: 'repository_agent_representation__agent_contacts__0__telephones__1_').text).to match(/999\-9999/)
    end
  end

  it 'cannot delete contact info subrecord from a repository record' do
    @driver.click_and_wait_until_gone(:link, 'Edit')

    expect do
      @driver.find_element_with_text('//*[@id="repository_agent_representation__agent_contacts__0_"]/a', //, false, true)
    end.to raise_error(Selenium::WebDriver::Error::NoSuchElementError)
  end

  it 'can add a an email signature to a repo record' do
    # This isn't in a normal corporate entitiy contact subrecord, so we want to be sure it's here
    @driver.clear_and_send_keys([:id, 'repository_agent_representation__agent_contacts__0__email_signature_'], 'Email signature')

    @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")
    @driver.find_element_with_text('//div[contains(@class, "alert-success")]', /Repository Saved/)

    assert(5) do
      expect(@driver.find_element_with_text('//div', /Email signature/)).not_to be_nil
    end
  end

  it 'will add a new contact name on save if the existing one is deleted' do
    @driver.click_and_wait_until_gone(:link, 'Edit')

    @driver.clear_and_send_keys([:id, 'repository_agent_representation__agent_contacts__0__name_'], '')

    @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")
    @driver.find_element_with_text('//div[contains(@class, "alert-success")]', /Repository Saved/)

    expect(@driver.find_elements(:xpath, '//*[@id="repository_agent_representation__agent_contacts__0_"]/div/div[1]/div')[0].text).to eq @test_repo_name_1
  end

  it 'will only display the first contact record if there are multiple' do
    # Add an additional contact record to the agent for this repository
    run_all_indexers
    @driver.navigate.to("#{$frontend}/agents")
    @driver.find_element(:link, 'Corporate Entity').click

    @driver.click_and_wait_until_element_gone(
      @driver.
        find_paginated_element(xpath: "//tr[./td[contains(., '#{@test_repo_name_1}')]]").
        find_element(:link, 'Edit')
    )

    @driver.find_element(css: '#agent_corporate_entity_contact_details .subrecord-form-heading .btn:not(.show-all)').click
    @driver.clear_and_send_keys(
      [:css, '#agent_corporate_entity_contact_details li:last-child input[id$="__name_"]'],
      'This is not the contact you are looking for'
    )

    @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")
    @driver.find_element_with_text('//div[contains(@class, "alert-success")]', /Agent Saved/)

    expect(@driver.find_element(id: 'agent_agent_contacts__0__name_').attribute('value')).to eq @test_repo_name_1
    expect(@driver.find_element(id: 'agent_agent_contacts__1__name_').attribute('value')).to match(/This is not the contact/)

    # Return to the repository record
    @driver.get("#{$frontend}/repositories")
    @driver.click_and_wait_until_element_gone(
      @driver.
        find_paginated_element(xpath: "//tr[./td[contains(., '#{@test_repo_code_1}')]]").
        find_element(:link, 'Edit')
    )

    expect(@driver.is_visible?(:css, "#repository_agent_representation__agent_contacts__0__name_")).to eq(true)
    expect(@driver.is_visible?(:css, "#repository_agent_representation__agent_contacts__1__name_")).to eq(false)

    # Kick back to the repositories page (tests are not isolated, required by next test)
    @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")
  end

  it 'does not display embedded note subrecord on repo page' do
    @driver.click_and_wait_until_gone(:link, 'Edit')

    expect do
      @driver.find_element_with_text('//*[@id="agent_contact"]/h4/button', /Add Contact Note/, false, true)
    end.to raise_error(Selenium::WebDriver::Error::NoSuchElementError)
  end

  it 'Cannot delete the currently selected repository' do
    run_index_round
    @driver.select_repo(@test_repo_code_1)
    @driver.get("#{$frontend}/repositories")
    row = @driver.find_paginated_element(xpath: "//tr[.//*[contains(text(), 'Selected')]]")
    row.click_and_wait_until_gone(:link, 'Edit')
    @driver.ensure_no_such_element(:css, 'button.delete-record')
  end

  it 'Can delete a repository' do
    @deletable_repo = create(:repo, repo_code: "deleteme_#{Time.now.to_i}")

    set_repo(@deletable_repo)

    5.times do
      create(:accession)
      create(:resource)
    end

    run_all_indexers

    @driver.get("#{$frontend}/repositories")
    row = @driver.find_paginated_element(xpath: "//tr[.//*[contains(text(), '#{@deletable_repo.repo_code}')]]")
    @driver.click_and_wait_until_element_gone(row.find_element(:link, 'Edit'))

    @driver.find_element(:css, '.delete-record.btn').click
    @driver.clear_and_send_keys([:id, 'deleteRepoConfim'], @deletable_repo.repo_code)
    @driver.wait_for_ajax

    @driver.find_element(:css, '#confirmChangesModal #confirmButton').click
    assert(5) { expect(@driver.find_element(css: 'div.alert.alert-success').text).to eq('Repository Deleted') }
  end

  it 'can create a second repository' do
    @driver.get("#{$frontend}/repositories")
    @driver.click_and_wait_until_gone(:link, 'Create Repository')
    @driver.clear_and_send_keys([:id, 'repository_repository__repo_code_'], @test_repo_code_2)
    @driver.clear_and_send_keys([:id, 'repository_repository__name_'], @test_repo_name_2)
    @driver.click_and_wait_until_gone(css: "form#new_repository button[type='submit']")
  end

  it 'can select either of the created repositories' do
    @driver.find_element(:link, 'Select Repository').click
    @driver.find_element(:css, '.select-a-repository select').select_option_with_text(@test_repo_code_2)
    @driver.click_and_wait_until_gone(:css, '.select-a-repository .btn-primary')
    expect(@driver.find_element(:css, 'span.current-repository-id').text).to eq @test_repo_code_2

    @driver.find_element(:link, 'Select Repository').click
    @driver.find_element(:css, '.select-a-repository select').select_option_with_text(@test_repo_code_1)
    @driver.click_and_wait_until_gone(:css, '.select-a-repository .btn-primary')
    expect(@driver.find_element(:css, 'span.current-repository-id').text).to eq @test_repo_code_1

    @driver.find_element(:link, 'Select Repository').click
    @driver.find_element(:css, '.select-a-repository select').select_option_with_text(@test_repo_code_2)
    @driver.click_and_wait_until_gone(:css, '.select-a-repository .btn-primary')
    expect(@driver.find_element(:css, 'span.current-repository-id').text).to eq @test_repo_code_2
  end

  it 'automatically refreshes the repository list when a new repo gets added' do
    repo = create(:repo)
    success = false

    Selenium::Config.retries.times do |_try|
      @driver.navigate.refresh

      @driver.find_element(:link, 'Select Repository').click
      res = @driver.execute_script("return $('option').filter(function (i, elt) { return $(elt).text() == '#{repo.repo_code}' }).length;")

      if res == 1
        success = true
        break
      end
    end

    expect(success).to be_truthy
  end
end
