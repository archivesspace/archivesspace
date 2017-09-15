require_relative 'spec_helper'

describe "Assessments" do

  before(:all) do
    @repo = create(:repo, :repo_code => "assessments_test_#{Time.now.to_i}")
    @other_repo = create(:repo, :repo_code => "assessments_test_2_#{Time.now.to_i}")
    set_repo @repo

    @accession = create(:accession, :title => "Accession to assess")
    @resource = create(:resource, :title => "Resource to assess")
    @digital_object = create(:digital_object, :title => "Digital Object to assess")
    @archival_object = create(:archival_object, :title => "Archival Object to assess",
                                                :resource => {
                                                  :ref => @resource.uri
                                                })

    @archivist_user = create_user(@repo => ['repository-archivists'])
    @manager_user = create_user(@repo => ['repository-managers'], @other_repo => ['repository-managers'])

    run_all_indexers

    @driver = Driver.get.login_to_repo(@manager_user, @repo)
  end


  after(:all) do
    @driver.quit
  end


  it "can add repository assessment attribute definitions" do
    @driver.find_element(:css, '.repo-container .btn.dropdown-toggle').click
    @driver.wait_for_dropdown
    @driver.click_and_wait_until_gone(:link, "Manage Assessment Attributes")

    # Add two ratings
    @driver.find_element(:css, '.add-repo-attribute[data-type=rating]').click
    @driver.clear_and_send_keys([:id, 'ratings__label'], 'Danceability')

    @driver.find_element(:css, '.add-repo-attribute[data-type=rating]').click
    second_rating_row = @driver.find_elements(:css, '.repository-attributes tr')[1]
    second_rating_row.clear_and_send_keys([:id, 'ratings__label'], 'Grooviness')

    # Add a format
    @driver.find_element(:css, '.add-repo-attribute[data-type=format]').click
    @driver.clear_and_send_keys([:id, 'formats__label'], 'Vinyl Record')

    # Add a conservation issue
    @driver.find_element(:css, '.add-repo-attribute[data-type=conservation_issue]').click
    @driver.clear_and_send_keys([:id, 'conservation_issues__label'], 'Scratched')

    @driver.click_and_wait_until_gone(:css => "form#assessment_attributes_form button[type='submit']")

    # Check they saved
    @driver.find_elements(:id, 'ratings__label')[0].attribute('value').should eq('Danceability')
    @driver.find_elements(:id, 'ratings__label')[1].attribute('value').should eq('Grooviness')
    @driver.find_element(:id, 'formats__label').attribute('value').should eq('Vinyl Record')
    @driver.find_element(:id, 'conservation_issues__label').attribute('value').should eq('Scratched')
  end


  it "can delete a repository attribute definition" do
    @driver.find_elements(:css, '.remove-repo-attribute')[1].click

    @driver.click_and_wait_until_gone(:css => "form#assessment_attributes_form button[type='submit']")

    @driver.find_elements(:id, 'ratings__label')[0].attribute('value').should eq('Danceability')
    @driver.find_element(:id, 'formats__label').attribute('value').should eq('Vinyl Record')
    @driver.find_element(:id, 'conservation_issues__label').attribute('value').should eq('Scratched')
  end


  it "check other repo doesn't have these attributes" do
    @driver.login_to_repo(@manager_user, @other_repo)
    @driver.find_element(:css, '.repo-container .btn.dropdown-toggle').click
    @driver.wait_for_dropdown
    @driver.click_and_wait_until_gone(:link, 'Manage Assessment Attributes')

    @driver.ensure_no_such_element(:id, 'ratings__label')
    @driver.ensure_no_such_element(:id, 'formats__label')
    @driver.ensure_no_such_element(:id, 'conservation_issues__label')
  end


  it 'can create an assessment with links to records and users' do
    @driver.login_to_repo(@archivist_user, @repo)
    @driver.find_element(:link, 'Create').click
    @driver.click_and_wait_until_gone(:link, 'Assessment')

    # Assess the accession and archival object
    token_input = @driver.find_element(:id, 'token-input-assessment_records_')
    token_input.clear
    token_input.send_keys('Accession')
    @driver.find_element(:css, 'li.token-input-dropdown-item2').click
    token_input.clear
    token_input.send_keys('Digital Object')
    @driver.find_element(:css, 'li.token-input-dropdown-item2').click
    token_input.clear
    token_input.send_keys('Archival Object')
    @driver.find_element(:css, 'li.token-input-dropdown-item2').click

    # To be surveyed by the archivist
    token_input = @driver.find_element(:id, 'token-input-assessment_surveyed_by_')
    token_input.clear
    token_input.send_keys(@archivist_user.username)
    @driver.find_element(:css, 'li.token-input-dropdown-item2').click

    # And reviewed by the repo manager
    @driver.find_element(:id, 'assessment_review_required_').click
    token_input = @driver.find_element(:id, 'token-input-assessment_reviewer_')
    token_input.clear
    token_input.send_keys(@manager_user.username)
    @driver.find_element(:css, 'li.token-input-dropdown-item2').click

    # Save!
    @driver.click_and_wait_until_gone(:css => "form#assessment_form button[type='submit']")

    # Check all were saved
    linked_records = @driver.find_elements(:css, "input[name='assessment[records][ref][]']")
    linked_records[0].attribute('value').should eq(@accession.uri)
    linked_records[1].attribute('value').should eq(@digital_object.uri)
    linked_records[2].attribute('value').should eq(@archival_object.uri)
    @driver.find_element(:css, ".token-input-token .accession").text.should match(/Accession to assess/)
    @driver.find_element(:css, ".token-input-token .digital_object").text.should match(/Digital Object to assess/)
    @driver.find_element(:css, ".token-input-token .archival_object").text.should match(/Archival Object to assess/)

    linked_agents = @driver.find_elements(:css, ".token-input-token .agent_person")
    linked_agents[0].text.should match(/#{@archivist_user.username}/)
    linked_agents[1].text.should match(/#{@manager_user.username}/)
  end


  it 'shows up in the listing' do
    run_all_indexers

    @driver.find_element(:link, "Browse").click
    @driver.click_and_wait_until_gone(:link, "Assessments")

    @driver.find_element_with_text('//div[contains(@class, "assessment-search-result-record-type")]', /Resource/)
    @driver.find_element_with_text('//ul[contains(@class, "assessment-search-result-listing")]/li', /#{@resource.title}/)
    @driver.find_element_with_text('//div[contains(@class, "assessment-search-result-record-type")]', /Archival Object/)
    @driver.find_element_with_text('//ul[contains(@class, "assessment-search-result-listing")]/li', /#{@archival_object.title}/)
    @driver.find_element_with_text('//div[contains(@class, "assessment-search-result-record-type")]', /Accession/)
    @driver.find_element_with_text('//ul[contains(@class, "assessment-search-result-listing")]/li', /#{@accession.title}/)
    @driver.find_element_with_text('//div[contains(@class, "assessment-search-result-record-type")]', /Digital Object/)
    @driver.find_element_with_text('//ul[contains(@class, "assessment-search-result-listing")]/li', /#{@digital_object.title}/)

    @driver.find_element_with_text('//td', /#{@archivist_user.username}/)
  end


  it 'can save ratings and ratings notes' do
    @driver.click_and_wait_until_gone(:link, 'Edit')

    # Documentation Quality
    @driver.find_element(:css, "#assessment_ratings__0__value_[value='1']").click
    # Housing Quality
    @driver.find_element(:css, "#assessment_ratings__1__value_[value='2']").click
    # Intellectual Access (description)
    @driver.find_element(:css, "#assessment_ratings__2__value_[value='3']").click
    # Interest
    @driver.find_element(:css, "#assessment_ratings__3__value_[value='4']").click
    # Physical Access (arrangement)
    @driver.find_element(:css, "#assessment_ratings__4__value_[value='5']").click
    # Physical Condition
    @driver.find_element(:css, "#assessment_ratings__5__value_[value='1']").click
    # Reformatting Readiness
    @driver.find_element(:css, "#assessment_ratings__6__value_[value='2']").click
    # Danceability
    @driver.find_element(:css, "#assessment_ratings__7__value_[value='5']").click
    # Danceability Note
    @driver.find_elements(:css, ".assessment-add-rating-note").last.click
    @driver.clear_and_send_keys([:id, "assessment_ratings__7__note_"], "Get your boogie on")

    @driver.click_and_wait_until_gone(:css => "form#assessment_form button[type='submit']")

    expect(@driver.execute_script("return $('#assessment_ratings__0__value_:checked').val()")).to eq('1')
    expect(@driver.execute_script("return $('#assessment_ratings__1__value_:checked').val()")).to eq('2')
    expect(@driver.execute_script("return $('#assessment_ratings__2__value_:checked').val()")).to eq('3')
    expect(@driver.execute_script("return $('#assessment_ratings__3__value_:checked').val()")).to eq('4')
    expect(@driver.execute_script("return $('#assessment_ratings__4__value_:checked').val()")).to eq('5')
    expect(@driver.execute_script("return $('#assessment_ratings__5__value_:checked').val()")).to eq('1')
    expect(@driver.execute_script("return $('#assessment_ratings__6__value_:checked').val()")).to eq('2')
    expect(@driver.execute_script("return $('#assessment_ratings__7__value_:checked').val()")).to eq('5')

    @driver.find_element(:id, 'assessment_ratings__7__note_')
    expect(@driver.execute_script("return $('#assessment_ratings__7__note_').val()")).to eq('Get your boogie on')
  end


  it 'can save formats' do
    # Audio Materials
    @driver.find_element(:css, "#assessment_formats__3__value_").click
    # Vinyl
    @driver.find_element(:css, "#assessment_formats__16__value_").click

    @driver.click_and_wait_until_gone(:css => "form#assessment_form button[type='submit']")

    expect(@driver.execute_script("return $('#assessment_formats__3__value_').is(':checked')")).to be_truthy
    expect(@driver.execute_script("return $('#assessment_formats__16__value_').is(':checked')")).to be_truthy
  end


  it 'can save conservation issues' do
    # Potential Mold or Mold Damage
    @driver.find_element(:css, "#assessment_conservation_issues__5__value_").click
    # Scratched
    @driver.find_element(:css, "#assessment_conservation_issues__9__value_").click

    @driver.click_and_wait_until_gone(:css => "form#assessment_form button[type='submit']")

    expect(@driver.execute_script("return $('#assessment_conservation_issues__5__value_').is(':checked')")).to be_truthy
    expect(@driver.execute_script("return $('#assessment_conservation_issues__9__value_').is(':checked')")).to be_truthy
  end


  it 'has all the values in the readonly view' do
    run_all_indexers

    @driver.find_element(:link, "Browse").click
    @driver.click_and_wait_until_gone(:link, "Assessments")
    @driver.click_and_wait_until_gone(:link, 'View')

    # linked records
    @driver.find_element(:css, ".token.accession").text.should match(/#{@accession.title}/)
    @driver.find_element(:css, ".token.archival_object").text.should match(/#{@archival_object.title}/)
    @driver.find_element(:css, ".token.digital_object").text.should match(/#{@digital_object.title}/)

    # linked agents
    linked_agents = @driver.find_elements(:css, ".token.agent_person")
    linked_agents[0].text.should match(/#{@archivist_user.username}/)
    linked_agents[1].text.should match(/#{@manager_user.username}/)

    # ratings
    expect(@driver.execute_script("return $('#rating_attributes_table').find('td:contains(\"Documentation Quality\")').parent().find('td')[1].innerText")).to eq('1')
    expect(@driver.execute_script("return $('#rating_attributes_table').find('td:contains(\"Housing Quality\")').parent().find('td')[1].innerText")).to eq('2')
    expect(@driver.execute_script("return $('#rating_attributes_table').find('td:contains(\"Intellectual Access\")').parent().find('td')[1].innerText")).to eq('3')
    expect(@driver.execute_script("return $('#rating_attributes_table').find('td:contains(\"Interest\")').parent().find('td')[1].innerText")).to eq('4')
    expect(@driver.execute_script("return $('#rating_attributes_table').find('td:contains(\"Physical Access\")').parent().find('td')[1].innerText")).to eq('5')
    expect(@driver.execute_script("return $('#rating_attributes_table').find('td:contains(\"Physical Condition\")').parent().find('td')[1].innerText")).to eq('1')
    expect(@driver.execute_script("return $('#rating_attributes_table').find('td:contains(\"Reformatting Readiness\")').parent().find('td')[1].innerText")).to eq('2')
    expect(@driver.execute_script("return $('#rating_attributes_table').find('td:contains(\"Danceability\")').parent().find('td')[1].innerText")).to eq('5')
    expect(@driver.execute_script("return $('#rating_attributes_table').find('td:contains(\"Research Value\")').parent().find('td')[1].innerText")).to eq('5') # Interest + Documentation Quality 
    expect(@driver.execute_script("return $('#rating_attributes_table').find('td:contains(\"Danceability\")').parent().find('td')[2].innerText")).to eq('Get your boogie on')

    # formats
    @driver.find_element_with_text('//section[@id="format_attributes"]//li', /Audio Materials/)
    @driver.find_element_with_text('//section[@id="format_attributes"]//li', /Vinyl/)

    # conservation issues
    @driver.find_element_with_text('//section[@id="conservation_issue_attributes"]//li', /Potential Mold or Mold Damage/)
    @driver.find_element_with_text('//section[@id="conservation_issue_attributes"]//li', /Scratched/)
  end


  it 'shows linked assessments on accession page' do
    @driver.navigate.to("#{$frontend}/resolve/readonly?uri=#{@accession.uri}")
    @driver.wait_for_ajax
    @driver.find_elements(:css, "#linked_assessments #tabledSearchResults tbody tr").length.should eq(1)
  end


  it 'shows linked assessments on archival object page' do
    @driver.navigate.to("#{$frontend}/resolve/readonly?uri=#{@archival_object.uri}")
    @driver.wait_for_ajax
    @driver.find_elements(:css, "#linked_assessments #tabledSearchResults tbody tr").length.should eq(1)
  end


  it 'shows linked assessments on digital object page' do
    @driver.navigate.to("#{$frontend}/resolve/readonly?uri=#{@digital_object.uri}")
    @driver.wait_for_ajax
    @driver.find_elements(:css, "#linked_assessments #tabledSearchResults tbody tr").length.should eq(1)
  end
end
