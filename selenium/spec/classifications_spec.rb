require_relative 'spec_helper'

describe "Classifications" do

  before(:all) do
    login_as_admin

    @classification_agent_uri, @classification_agent_name = create_agent("Classification Agent #{Time.now.to_i}_#{$$}")
    run_index_round
  end


  after(:all) do
    logout
  end


  test_classification = "Classification #{Time.now.to_i}_#{$$}"
  test_classification_term = "Classification Term #{Time.now.to_i}_#{$$}"

  it "allows you to create a classification tree" do
    $driver.find_element(:link, "Create").click
    $driver.find_element(:link, "Classification").click

    $driver.clear_and_send_keys([:id, 'classification_identifier_'], "10")
    $driver.clear_and_send_keys([:id, 'classification_title_'], test_classification)

    token_input = $driver.find_element(:id, "token-input-classification_creator__ref_")
    token_input.clear
    token_input.click
    token_input.send_keys(@classification_agent_name)
    $driver.find_element(:css, "li.token-input-dropdown-item2").click

    $driver.click_and_wait_until_gone(:css => "form#classification_form button[type='submit']")

    $driver.find_element_with_text('//div[contains(@class, "alert-success")]', /Classification.*created/i)

    $driver.find_element_with_text('//div[contains(@class, "agent_person")]', /#{@classification_agent_name}/i)
  end


  it "allows you to create a classification term" do
    $driver.find_element(:link, "Add Child").click

    $driver.clear_and_send_keys([:id, 'classification_term_identifier_'], "11")
    $driver.clear_and_send_keys([:id, 'classification_term_title_'], test_classification_term)

    token_input = $driver.find_element(:id, "token-input-classification_term_creator__ref_")
    token_input.clear
    token_input.click
    token_input.send_keys(@classification_agent_name)
    $driver.find_element(:css, "li.token-input-dropdown-item2").click

    $driver.click_and_wait_until_gone(:css => "form#classification_term_form button[type='submit']")

    $driver.find_element_with_text('//div[contains(@class, "alert-success")]', /Classification Term.*created/i)

    $driver.find_element_with_text('//div[contains(@class, "agent_person")]', /#{@classification_agent_name}/i)
  end


  it "allows you to link a resource to a classification" do
    $driver.find_element(:link, "Create").click
    $driver.find_element(:link, "Resource").click

    $driver.clear_and_send_keys([:id, "resource_title_"], "a resource")
    $driver.complete_4part_id("resource_id_%d_")
    combo = $driver.find_element(:xpath => '//div[@class="combobox-container"][following-sibling::select/@id="resource_language_"]//input[@type="text"]');
    combo.clear
    combo.click
    combo.send_keys("eng")
    combo.send_keys(:tab)
    $driver.find_element(:id, "resource_level_").select_option("collection")
    $driver.clear_and_send_keys([:id, "resource_extents__0__number_"], "10")
    $driver.find_element(:id => "resource_extents__0__extent_type_").select_option("files")

    $driver.find_element(:id => "resource_dates__0__date_type_").select_option("single")
    $driver.clear_and_send_keys([:id, "resource_dates__0__begin_"], "1978")

    # Now add a classification
    $driver.find_element(:css => '#resource_classifications_ .subrecord-form-heading .btn:not(.show-all)').click

    run_all_indexers

    assert(5) {
      $driver.clear_and_send_keys([:id, "token-input-resource_classifications__0__ref_"],
                                  test_classification)
      $driver.find_element(:css, "li.token-input-dropdown-item2").click
    }
    
    $driver.find_element(:css => '#resource_classifications_ .subrecord-form-heading .btn:not(.show-all)').click
    assert(5) {
      $driver.clear_and_send_keys([:id, "token-input-resource_classifications__1__ref_"],
                                  test_classification_term)
      $driver.find_element(:css, "li.token-input-dropdown-item2").click
    }

    $driver.click_and_wait_until_gone(:css => "form#resource_form button[type='submit']")
    $driver.click_and_wait_until_gone(:link, "Close Record")

    $driver.find_element(:css => 'div.token.classification').text.should match(/#{test_classification}/)
    $driver.find_element(:css => 'div.token.classification_term').text.should match(/#{test_classification_term}/)
  end


  it "allows you to link an accession to a classification" do
    $driver.find_element(:link, "Create").click
    $driver.find_element(:link, "Accession").click

    accession_title = "Tomorrow's Harvest"
    accession_4part_id = $driver.generate_4part_id

    $driver.clear_and_send_keys([:id, "accession_title_"], accession_title)
    $driver.complete_4part_id("accession_id_%d_", accession_4part_id)

    $driver.clear_and_send_keys([:id, "accession_accession_date_"], "2013-06-11")

    # Now add a classification
    $driver.find_element(:css => '#accession_classifications_ .subrecord-form-heading .btn:not(.show-all)').click

    assert(5) {
      run_index_round
      $driver.clear_and_send_keys([:id, "token-input-accession_classifications__0__ref_"],
                                  test_classification)
      $driver.find_element(:css, "li.token-input-dropdown-item2").click
    }

    $driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")

    $driver.click_and_wait_until_gone(:link => accession_title)

    $driver.find_element(:css => 'div.token.classification').text.should match(/#{test_classification}/)
  end
end
