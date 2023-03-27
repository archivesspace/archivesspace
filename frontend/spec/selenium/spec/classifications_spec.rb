# frozen_string_literal: true

require_relative '../spec_helper'

describe 'Classifications' do
  before(:all) do
    @repo = create(:repo, repo_code: "classification_test_#{Time.now.to_i}")
    set_repo(@repo)

    @classification_agent = create(:agent_person)
    @agent_sort_name = @classification_agent.names.first['sort_name']

    @driver = Driver.get.login($admin)

    run_index_round
    @driver.select_repo(@repo.repo_code)
  end

  after(:all) do
    @driver ? @driver.quit : next
  end

  test_classification = "Classification #{Time.now.to_i}_#{$$}"
  test_classification_term = "Classification Term #{Time.now.to_i}_#{$$}"

  it 'allows you to create a classification tree' do
    @driver.find_element(:link, 'Create').click
    @driver.click_and_wait_until_gone(:link, 'Classification')

    @driver.clear_and_send_keys([:id, 'classification_identifier_'], '10')
    @driver.clear_and_send_keys([:id, 'classification_title_'], test_classification)

    token_input = @driver.find_element(:id, 'token-input-classification_creator__ref_')

    # generated name starts with "Name". For some reason, selenium is picking a different object when using the variable "@agent_sort_name"
    @driver.typeahead_and_select(token_input, @agent_sort_name)

    @driver.click_and_wait_until_gone(css: "form#classification_form button[type='submit']")

    @driver.find_element_with_text('//div[contains(@class, "alert-success")]', /Classification.*created/i)

    expect(@driver.find_element(:css, 'div.agent_person').text).to eq(@agent_sort_name)
  end

  it 'allows you to create a classification term' do
    @driver.find_element(:link, 'Add Child').click

    @driver.clear_and_send_keys([:id, 'classification_term_identifier_'], '11')
    @driver.clear_and_send_keys([:id, 'classification_term_title_'], test_classification_term)

    token_input = @driver.find_element(:id, 'token-input-classification_term_creator__ref_')
    @driver.typeahead_and_select(token_input, @agent_sort_name)

    @driver.click_and_wait_until_gone(css: "form#classification_term_form button[type='submit']")

    @driver.find_element_with_text('//div[contains(@class, "alert-success")]', /Classification Term.*created/i)

    expect(@driver.find_element(:css, 'div.agent_person').text).to eq(@agent_sort_name)
  end

  it 'allows you to link a resource to a classification' do
    @driver.find_element(:link, 'Create').click
    @driver.click_and_wait_until_gone(:link, 'Resource')

    @driver.find_hidden_element(:css, '#resource_title_').wait_for_class('initialised')
    @driver.execute_script("$('#resource_title_').data('CodeMirror').setValue('a resource')")
    @driver.complete_4part_id('resource_id_%d_')
    @driver.find_element(:id, 'resource_level_').select_option('collection')

    combo = @driver.find_element(xpath: '//*[@id="resource_lang_materials__0__language_and_script__language_"]')
    combo.clear
    combo.click
    combo.send_keys('eng')
    combo.send_keys(:tab)

    @driver.clear_and_send_keys([:id, 'resource_extents__0__number_'], '10')
    @driver.find_element(id: 'resource_extents__0__extent_type_').select_option('cassettes')

    @driver.find_element(id: 'resource_dates__0__date_type_').select_option('single')
    @driver.clear_and_send_keys([:id, 'resource_dates__0__begin_'], '1978')

    sleep 2

    combo = @driver.find_element(xpath: '//*[@id="resource_finding_aid_language_"]')
    combo.clear
    combo.click
    combo.send_keys('eng')
    combo.send_keys(:tab)

    combo = @driver.find_element(xpath: '//*[@id="resource_finding_aid_script_"]')
    combo.clear
    combo.click
    combo.send_keys('Latin')
    combo.send_keys(:tab)

    # Now add a classification
    @driver.find_element(css: '#resource_classifications_ .subrecord-form-heading .btn:not(.show-all)').click

    run_all_indexers

    assert(5) do
      @driver.clear_and_send_keys([:id, 'token-input-resource_classifications__0__ref_'],
                                  test_classification)
      sleep 1
      @driver.find_element(:css, 'li.token-input-dropdown-item2').click
    end

    @driver.find_element(css: '#resource_classifications_ .subrecord-form-heading .btn:not(.show-all)').click
    assert(5) do
      @driver.clear_and_send_keys([:id, 'token-input-resource_classifications__1__ref_'],
                                  test_classification_term)
      sleep 1
      @driver.find_element(:css, 'li.token-input-dropdown-item2').click
    end

    @driver.click_and_wait_until_gone(css: "form#resource_form button[type='submit']")
    sleep 1
    @driver.click_and_wait_until_gone(:link, 'Close Record')

    expect(@driver.find_element(css: 'div.token.classification').text).to match(/#{test_classification}/)
    expect(@driver.find_element(css: 'div.token.classification_term').text).to match(/#{test_classification_term}/)
  end

  it 'allows you to link an accession to a classification' do
    @driver.find_element(:link, 'Create').click
    @driver.click_and_wait_until_gone(:link, 'Accession')

    accession_title = "Tomorrow's Harvest"
    accession_4part_id = @driver.generate_4part_id

    @driver.find_hidden_element(:css, '#accession_title_').wait_for_class('initialised')
    @driver.execute_script("$('#accession_title_').data('CodeMirror').setValue(\"#{accession_title}\")")

    @driver.complete_4part_id('accession_id_%d_', accession_4part_id)

    @driver.clear_and_send_keys([:id, 'accession_accession_date_'], '2013-06-11')

    # Now add a classification
    @driver.find_element(css: '#accession_classifications_ .subrecord-form-heading .btn:not(.show-all)').click

    assert(5) do
      run_index_round
      token_input = @driver.find_element(:id, 'token-input-accession_classifications__0__ref_')
      @driver.typeahead_and_select(token_input, test_classification)
    end

    @driver.click_and_wait_until_gone(css: "form#accession_form button[type='submit']")

    @driver.click_and_wait_until_gone(link: accession_title)

    expect(@driver.find_element(css: 'div.token.classification').text).to match(/#{test_classification}/)
  end

  it 'has the linked records on the classifications view page' do
    a_resource = create(:resource)

    a_classification = create(:classification, linked_records: [{ ref: a_resource.uri }])
    a_term = create(:classification_term,
                    classification: { 'ref' => a_classification.uri })
    an_accession = create(:accession, classifications: [{ ref: a_term.uri }])

    run_all_indexers

    @driver.get_view_page(a_classification)
    expect(@driver.find_element(:css, '#classifications').text).to match(/#{a_resource.title}/)
    sleep 30
    tree_click(tree_node(a_term))
    @driver.wait_for_ajax
    expect(@driver.find_element(:css, '#classifications').text).to match(/#{an_accession.title}/)
  end
end
