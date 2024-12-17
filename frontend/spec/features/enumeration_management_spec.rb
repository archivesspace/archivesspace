# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Enumeration Management', js: true do
  let(:admin) { BackendClientMethods::ASpaceUser.new('admin', 'admin') }
  let!(:repository) { create(:repo, repo_code: "enum_test_#{Time.now.to_i}", publish: true) }

  before(:each) do
    login_user(admin)
    select_repository(repository)
  end

  it 'lets you add a new value to an enumeration' do
    now = Time.now.to_i
    click_on 'System'
    click_on 'Manage Controlled Value Lists'

    element = find('.alert.alert-info.with-hide-alert')
    expect(element.text).to eq 'Please select a Controlled Value List'

    select 'Accession Acquisition Type (accession_acquisition_type)', from: 'enum_selector'

    element = find('a', text: 'Create Value')
    element.click

    within '#form_enumeration' do
      fill_in 'enumeration_value_', with: "enumaration_value_#{now}"
      click_on 'Create Value'
    end

    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq 'Value Created'
    expect(page).to have_css 'tr', text: "enumaration_value_#{now}"
  end

  it 'lets you delete a value from an enumeration' do
    now = Time.now.to_i
    click_on 'System'
    click_on 'Manage Controlled Value Lists'
    element = find('.alert.alert-info.with-hide-alert')
    expect(element.text).to eq 'Please select a Controlled Value List'

    select 'Accession Acquisition Type (accession_acquisition_type)', from: 'enum_selector'

    element = find('a', text: 'Create Value')
    element.click

    within '#form_enumeration' do
      fill_in 'enumeration_value_', with: "enumaration_value_#{now}"
      click_on 'Create Value'
    end

    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq 'Value Created'

    element = find('tr', text: "enumaration_value_#{now}")
    within element do
      click_on 'Delete'
    end

    within '#form_enumeration' do
      click_on 'Delete Value'
    end

    expect(page).to_not have_css 'tr', text: "enumaration_value_#{now}"
  end

  it 'lets you merge one value into another in an enumeration' do
    now = Time.now.to_i
    enumeration_a = "Enumeration_a_#{now}"
    enumeration_b = "Enumeration_b_#{now}"
    click_on 'System'
    click_on 'Manage Controlled Value Lists'
    element = find('.alert.alert-info.with-hide-alert')
    expect(element.text).to eq 'Please select a Controlled Value List'

    select 'Accession Acquisition Type (accession_acquisition_type)', from: 'enum_selector'

    element = find('a', text: 'Create Value')
    element.click
    within '#form_enumeration' do
      fill_in 'enumeration_value_', with: "#{enumeration_a}"
      click_on 'Create Value'
    end
    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq 'Value Created'
    expect(page).to have_css 'tr', text: enumeration_a

    element = find('a', text: 'Create Value')
    element.click
    within '#form_enumeration' do
      fill_in 'enumeration_value_', with: "#{enumeration_b}"
      click_on 'Create Value'
    end
    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq 'Value Created'

    element = find('tr', text: enumeration_b)
    within element do
      click_on 'Merge'
    end

    within '#form_enumeration' do
      select enumeration_a, from: 'merge_into'
      click_on 'Merge Value'
    end

    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq 'Value Merged'

    expect(page).to_not have_css 'tr', text: enumeration_b
  end

  it 'lets you set a default enumeration (date_type)' do
    click_on 'System'
    click_on 'Manage Controlled Value Lists'
    element = find('.alert.alert-info.with-hide-alert')
    expect(element.text).to eq 'Please select a Controlled Value List'

    select 'Date Type (date_type)', from: 'enum_selector'

    elements = all('tr', text: 'Set as Default')
    expect(elements.length > 0).to eq true

    default_value = elements[0].all('td').first.text

    within elements[0] do
      click_on 'Set as Default'
    end

    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq 'Default Value Set'

    click_on 'Create'
    click_on 'Accession'
    click_on 'Add Date'

    element = find('#accession_dates__0__date_type_')

    expect(element.value).to eq default_value
  end

  it 'lets you add a new value to an enumeration, reorder it and then you can use it' do
    now = Time.now.to_i
    click_on 'System'
    click_on 'Manage Controlled Value Lists'
    element = find('.alert.alert-info.with-hide-alert')
    expect(element.text).to eq 'Please select a Controlled Value List'

    select 'Collection Management Processing Priority (collection_management_processing_priority)', from: 'enum_selector'

    element = find('a', text: 'Create Value')
    element.click

    within '#form_enumeration' do
      fill_in 'enumeration_value_', with: "enumaration_value_#{now}"
      click_on 'Create Value'
    end

    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq 'Value Created'
    expect(page).to have_css 'tr', text: "enumaration_value_#{now}"

    click_on 'Create'
    click_on 'Accession'
    fill_in 'accession_title_', with: "Accession Title #{now}"
    fill_in 'accession_id_0_', with: "1 #{now}"
    fill_in 'accession_id_1_', with: "2 #{now}"
    fill_in 'accession_id_2_', with: "3 #{now}"
    fill_in 'accession_id_3_', with: "4 #{now}"
    fill_in 'accession_accession_date_', with: '2012-01-01'
    fill_in 'accession_content_description_', with: "Accession Description #{now}"
    fill_in 'accession_condition_description_', with: "Accession Condition Description #{now}"
    click_on 'Add Collection Management Fields'
    select "enumaration_value_#{now}", from: 'accession_collection_management__processing_priority_'

    # Click on save
    find('button', text: 'Save Accession', match: :first).click
    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq "Accession Accession Title #{now} created"

    find('a', text: "Accession Title #{now}").click

    element = find('#accession_collection_management__accordion')
    expect(element).to have_text "enumaration_value_#{now}"
  end

  it 'lets you see how many times the term has been used and search for it' do
    now = Time.now.to_i
    click_on 'System'
    click_on 'Manage Controlled Value Lists'
    element = find('.alert.alert-info.with-hide-alert')
    expect(element.text).to eq 'Please select a Controlled Value List'

    select 'Collection Management Processing Priority (collection_management_processing_priority)', from: 'enum_selector'

    element = find('a', text: 'Create Value')
    element.click

    within '#form_enumeration' do
      fill_in 'enumeration_value_', with: "enumaration_value_#{now}"
      click_on 'Create Value'
    end

    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq 'Value Created'
    expect(page).to have_css 'tr', text: "enumaration_value_#{now}"

    click_on 'Create'
    click_on 'Accession'
    fill_in 'accession_title_', with: "Accession Title #{now}"
    fill_in 'accession_id_0_', with: "1 #{now}"
    fill_in 'accession_id_1_', with: "2 #{now}"
    fill_in 'accession_id_2_', with: "3 #{now}"
    fill_in 'accession_id_3_', with: "4 #{now}"
    fill_in 'accession_accession_date_', with: '2012-01-01'
    fill_in 'accession_content_description_', with: "Accession Description #{now}"
    fill_in 'accession_condition_description_', with: "Accession Condition Description #{now}"
    click_on 'Add Collection Management Fields'
    select "enumaration_value_#{now}", from: 'accession_collection_management__processing_priority_'

    # Click on save
    find('button', text: 'Save Accession', match: :first).click
    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq "Accession Accession Title #{now} created"

    run_index_round

    visit '/'
    click_on 'System'
    click_on 'Manage Controlled Value Lists'
    select 'Collection Management Processing Priority (collection_management_processing_priority)', from: 'enum_selector'

    element = find('tr', text: "enumaration_value_#{now}")
    expect(element).to have_text '1 related item'
  end

  it 'lets you suppress an enumeration value' do
    now = Time.now.to_i
    click_on 'System'
    click_on 'Manage Controlled Value Lists'
    element = find('.alert.alert-info.with-hide-alert')
    expect(element.text).to eq 'Please select a Controlled Value List'

    select 'Collection Management Processing Priority (collection_management_processing_priority)', from: 'enum_selector'

    element = find('a', text: 'Create Value')
    element.click

    within '#form_enumeration' do
      fill_in 'enumeration_value_', with: "enumaration_value_#{now}"
      click_on 'Create Value'
    end

    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq 'Value Created'

    element = find('tr', text: "enumaration_value_#{now}")
    within element do
      click_on 'Suppress'
    end

    element = find('tr', text: "enumaration_value_#{now}")
    expect(element).to have_css 'a', text: 'Unsuppress'

    click_on 'Create'
    click_on 'Accession'
    fill_in 'accession_title_', with: "Accession Title #{now}"
    fill_in 'accession_id_0_', with: "1 #{now}"
    fill_in 'accession_id_1_', with: "2 #{now}"
    fill_in 'accession_id_2_', with: "3 #{now}"
    fill_in 'accession_id_3_', with: "4 #{now}"
    fill_in 'accession_accession_date_', with: '2012-01-01'
    fill_in 'accession_content_description_', with: "Accession Description #{now}"
    fill_in 'accession_condition_description_', with: "Accession Condition Description #{now}"
    click_on 'Add Collection Management Fields'

    elements = all('#accession_collection_management__processing_priority_ option')
    options = elements.map { |option| option.value  }
    expect(options.include?("enumaration_value_#{now}")).to eq false

    # Click on save
    find('button', text: 'Save Accession', match: :first).click
    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq "Accession Accession Title #{now} created"
  end

  it 'lets you delete a suppressed enumeration value' do
    # TODO: somehow the test is ending up with a "Value Updated" message instead of "Value Deleted", but manual
    # testing indicates the features works as expected with the "Value Deleted" message appearing
    now = Time.now.to_i
    click_on 'System'
    click_on 'Manage Controlled Value Lists'
    element = find('.alert.alert-info.with-hide-alert')
    expect(element.text).to eq 'Please select a Controlled Value List'

    select 'Collection Management Processing Priority (collection_management_processing_priority)', from: 'enum_selector'

    element = find('a', text: 'Create Value')
    element.click

    within '#form_enumeration' do
      fill_in 'enumeration_value_', with: "enumaration_value_#{now}"
      click_on 'Create Value'
    end

    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq 'Value Created'

    element = find('tr', text: "enumaration_value_#{now}")
    within element do
      click_on 'Suppress'
    end

    element = find('tr', text: "enumaration_value_#{now}")
    within element do
      click_on 'Delete'
    end

    within '#form_enumeration' do
      click_on 'Delete Value'
    end

    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq 'Value Deleted'

    expect(page).to_not have_css 'tr', text: "enumaration_value_#{now}"
  end

  it 'lets you set a default value with another value suppressed' do
    now = Time.now.to_i
    click_on 'System'
    click_on 'Manage Controlled Value Lists'

    element = find('.alert.alert-info.with-hide-alert')
    expect(element.text).to eq 'Please select a Controlled Value List'

    select 'Record Control Level of Detail (level_of_detail)', from: 'enum_selector'

    element = find('tr', text: 'natc')
    within element do
      click_on 'Suppress'
    end

    element = find('tr', text: 'not_applicable')
    within element do
      click_on 'Set as Default'
    end

    element = find('tr', text: 'not_applicable')
    within element do
      click_on 'Unset Default'
    end
  end
end
