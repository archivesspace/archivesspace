# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Resources Form', js: true do
  let(:admin_user) { BackendClientMethods::ASpaceUser.new('admin', 'admin') }

  before(:all) do
    @repository = create(:repo, repo_code: "resources_test_#{Time.now.to_i}")
    create_subjects

    run_all_indexers
  end

  before(:each) do
    login_user(admin_user)
    select_repository(@repository)

    @resource = create(:resource)
    run_index_round
  end

  describe 'search dropdown and subject selection' do
    before(:each) do
      visit "resources/#{@resource.id}/edit"
      expect(page).to have_text @resource.title

      click_on 'Add Subject'
    end

    xit 'displays the correct icon and selects the option for cultural_context term_type, and checks the edit and show pages include it after save' do
      # AJAX drodown
      element = find('#resource_subjects_ input')
      element.fill_in with: 'cultural_context'

      # Check for icon
      element = find('.subject_type_cultural_context', match: :first)
      # Select option from dropdown
      element.click

      find('.icon-token.subject_type_cultural_context')
      expect(page).to have_text 'cultural_context'

      # Save
      find('button', text: 'Save', match: :first).click
      expect(page).to have_text "Resource #{@resource.title} updated"

      # Check edit page
      visit "resources/#{@resource.id}/edit"
      find('.icon-token.subject_type_cultural_context')

      # Check show page
      visit "resources/#{@resource.id}"
      find('.icon-token.subject_type_cultural_context')
    end

    xit 'displays the correct icon and selects the option for function term_type, and checks the edit and show pages include it after save' do
      # AJAX drodown
      element = find('#resource_subjects_ input')
      element.fill_in with: '  function'

      # Check for icon
      expect(page).to have_css '.subject_type_function'
      # Select option from dropdown
      element = find(:xpath, '//*[contains(@class, "subject") and contains(text(), "function")]')
      element.click

      find('.icon-token.subject_type_function')
      expect(page).to have_text 'function'

      # Save
      find('button', text: 'Save', match: :first).click
      expect(page).to have_text "Resource #{@resource.title} updated"

      # Check edit page
      visit "resources/#{@resource.id}/edit"
      find('.icon-token.subject_type_function')

      # Check show page
      visit "resources/#{@resource.id}"
      find('.icon-token.subject_type_function')
    end

    xit 'displays the correct icon and selects the option for genre_form term_type, and checks the edit and show pages include it after save' do
      # AJAX drodown
      element = find('#resource_subjects_ input')
      element.fill_in with: '  genre_form'

      # Check for icon
      expect(page).to have_css '.subject_type_genre_form'
      # Select option from dropdown
      element = find(:xpath, '//*[contains(@class, "subject") and contains(text(), "genre_form")]')
      element.click

      find('.icon-token.subject_type_genre_form')
      expect(page).to have_text 'genre_form'

      # Save
      find('button', text: 'Save', match: :first).click
      expect(page).to have_text "Resource #{@resource.title} updated"

      # Check edit page
      visit "resources/#{@resource.id}/edit"
      find('.icon-token.subject_type_genre_form')

      # Check show page
      visit "resources/#{@resource.id}"
      find('.icon-token.subject_type_genre_form')
    end

    xit 'displays the correct icon and selects the option for technique term_type, and checks the edit and show pages include it after save' do
      # AJAX drodown
      element = find('#resource_subjects_ input')
      element.fill_in with: '  technique'

      # Check for icon
      expect(page).to have_css '.subject_type_technique'
      # Select option from dropdown
      element = find(:xpath, '//*[contains(@class, "subject") and contains(text(), "technique")]')
      element.click

      find('.icon-token.subject_type_technique')
      expect(page).to have_text 'technique'

      # Save
      find('button', text: 'Save', match: :first).click
      expect(page).to have_text "Resource #{@resource.title} updated"

      # Check edit page
      visit "resources/#{@resource.id}/edit"
      find('.icon-token.subject_type_technique')

      # Check show page
      visit "resources/#{@resource.id}"
      find('.icon-token.subject_type_technique')
    end

    xit 'displays the correct icon and selects the option for occupation term_type, and checks the edit and show pages include it after save' do
      # AJAX drodown
      element = find('#resource_subjects_ input')
      element.fill_in with: '  occupation'

      # Check for icon
      expect(page).to have_css '.subject_type_occupation'
      # Select option from dropdown
      element = find(:xpath, '//*[contains(@class, "subject") and contains(text(), "occupation")]')
      element.click

      find('.icon-token.subject_type_occupation')
      expect(page).to have_text 'occupation'

      # Save
      find('button', text: 'Save', match: :first).click
      expect(page).to have_text "Resource #{@resource.title} updated"

      # Check edit page
      visit "resources/#{@resource.id}/edit"
      find('.icon-token.subject_type_occupation')

      # Check show page
      visit "resources/#{@resource.id}"
      find('.icon-token.subject_type_occupation')
    end

    xit 'displays the correct icon and selects the option for style_period term_type, and checks the edit and show pages include it after save' do
      # AJAX drodown
      element = find('#resource_subjects_ input')
      element.fill_in with: '  style_period'

      # Check for icon
      expect(page).to have_css '.subject_type_style_period'
      # Select option from dropdown
      element = find(:xpath, '//*[contains(@class, "subject") and contains(text(), "style_period")]')
      element.click

      find('.icon-token.subject_type_style_period')
      expect(page).to have_text 'style_period'

      # Save
      find('button', text: 'Save', match: :first).click
      expect(page).to have_text "Resource #{@resource.title} updated"

      # Check edit page
      visit "resources/#{@resource.id}/edit"
      find('.icon-token.subject_type_style_period')

      # Check show page
      visit "resources/#{@resource.id}"
      find('.icon-token.subject_type_style_period')
    end

    xit 'displays the correct icon and selects the option for temporal term_type, and checks the edit and show pages include it after save' do
      # AJAX drodown
      element = find('#resource_subjects_ input')
      element.fill_in with: '  temporal'

      # Check for icon
      expect(page).to have_css '.subject_type_temporal'

      # Select option from dropdown
      element = find(:xpath, '//*[contains(@class, "subject") and contains(text(), "temporal")]')
      element.click

      find('.icon-token.subject_type_temporal')
      expect(page).to have_text 'temporal'

      # Save
      find('button', text: 'Save', match: :first).click
      expect(page).to have_text "Resource #{@resource.title} updated"

      # Check edit page
      visit "resources/#{@resource.id}/edit"
      find('.icon-token.subject_type_temporal')

      # Check show page
      visit "resources/#{@resource.id}"
      find('.icon-token.subject_type_temporal')
    end

    xit 'displays the correct icon and selects the option for topical term_type, and checks the edit and show pages include it after save' do
      # AJAX drodown
      element = find('#resource_subjects_ input')
      element.fill_in with: '  topical'

      # Check for icon
      expect(page).to have_css '.subject_type_topical'
      # Select option from dropdown
      element = find(:xpath, '//*[contains(@class, "subject") and contains(text(), "topical")]')
      element.click

      find('.icon-token.subject_type_topical')
      expect(page).to have_text 'topical'

      # Save
      find('button', text: 'Save', match: :first).click
      expect(page).to have_text "Resource #{@resource.title} updated"

      # Check edit page
      visit "resources/#{@resource.id}/edit"
      find('.icon-token.subject_type_topical')

      # Check show page
      visit "resources/#{@resource.id}"
      find('.icon-token.subject_type_topical')
    end

    xit 'displays the correct icon and selects the option for uniform_title term_type, and checks the edit and show pages include it after save' do
      # AJAX drodown
      element = find('#resource_subjects_ input')
      element.fill_in with: '  uniform_title'

      # Check for icon
      expect(page).to have_css '.subject_type_uniform_title'

      # Select option from dropdown
      element = find(:xpath, '//*[contains(@class, "subject") and contains(text(), "uniform_title")]')
      element.click

      find('.icon-token.subject_type_uniform_title')
      expect(page).to have_text 'uniform_title'

      # Save
      find('button', text: 'Save', match: :first).click
      expect(page).to have_text "Resource #{@resource.title} updated"

      # Check edit page
      visit "resources/#{@resource.id}/edit"
      find('.icon-token.subject_type_uniform_title')

      # Check show page
      visit "resources/#{@resource.id}"
      find('.icon-token.subject_type_uniform_title')
    end
  end
end
