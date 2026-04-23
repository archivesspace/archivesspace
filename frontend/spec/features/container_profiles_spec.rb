# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Container Profiles', js: true do
  before(:all) do
    @repository = create(:repo, repo_code: "container_profiles_test_#{Time.now.to_i}", publish: true)
    @user = create_user(@repository => ['repository-archivists'])

    run_all_indexers
  end

  before(:each) do
    login_user(@user)
    select_repository(@repo)
  end

  it 'can create a container profile' do
    now = Time.now.to_i

    click_on 'Create'
    click_on 'Container Profile'

    fill_in 'Name', with: "Container Profile Name #{now}"
    select 'Millimeters', from: 'Dimension Units'
    select 'Depth', from: 'Extent Dimension'
    fill_in 'Depth', with: '1'
    fill_in 'Height', with: '2'
    fill_in 'Width', with: '3'

    # Click on save
    element = find('button', text: 'Save Container Profile', match: :first)
    element.click

    expect(page).to have_text 'Container Profile Created'
  end

  it 'cannot create a container profile with non-digit dimensions' do
    now = Time.now.to_i

    click_on 'Create'
    click_on 'Container Profile'

    fill_in 'Name', with: "Container Profile Name #{now}"
    select 'Millimeters', from: 'Dimension Units'
    select 'Depth', from: 'Extent Dimension'
    fill_in 'Depth', with: '1.1mm'
    fill_in 'Height', with: '2.2222'
    fill_in 'Width', with: '3.3m'

    # Click on save
    element = find('button', text: 'Save Container Profile', match: :first)
    element.click

    expect(page).to have_text 'Depth - Must be a number with no more than 2 decimal places'
    expect(page).to have_text 'Height - Must be a number with no more than 2 decimal places'
    expect(page).to have_text 'Width - Must be a number with no more than 2 decimal places'

    fill_in 'Depth', with: '1.11'
    fill_in 'Height', with: '2.22'
    fill_in 'Width', with: '3.33'

    # Click on save
    element = find('button', text: 'Save Container Profile', match: :first)
    element.click

    expect(page).to have_text 'Container Profile Created'
  end

  it 'can merge container profiles from browse when a repository manager' do
    now = Time.now.to_i

    profile_a = create(:json_container_profile, :name => "Container Profile A #{now}")
    profile_b = create(:json_container_profile, :name => "Container Profile B #{now}")

    run_index_round

    click_on 'Browse'
    click_on 'Container Profiles'

    element = find(:xpath, "//table//tr[td[contains(., '#{profile_a.name}')]]")
    within element do
      find('#multiselect-item').click
    end

    element = find(:xpath, "//table//tr[td[contains(., '#{profile_b.name}')]]")
    within element do
      find('#multiselect-item').click
    end

    click_on 'Merge'

    within '#batchMergeModal' do
      within '#mergeList' do
        find(:css, "[id='/container_profiles/#{profile_a.id}']").click
      end

      click_on 'Select merge destination'
    end

    within '#bulkMergeConfirmModal' do
      click_on 'Merge 2 records'
    end

    expect(page).to have_text 'Container Profiles(s) Merged'

    run_index_round

    visit '/'
    click_on 'Browse'
    click_on 'Container Profiles'
    expect(page).to have_text profile_a.name

    # Search for merged record
    input_text = find('#filter-text')
    input_text.fill_in with: profile_b.name
    input_text.send_keys(:enter)
    expect(page).to have_text 'No records found'
  end

  context 'index view' do
    describe 'results table' do
      let(:now) { Time.now.to_i }
      let(:record_type) { 'container_profile' }
      let(:browse_path) { '/container_profiles' }
      let(:record_1) { create(:container_profile, name: "Container Profile B #{now}") }
      let(:record_2) { create(:container_profile, name: "Container Profile A #{now}") }
      let(:filter_results) { true }
      let(:initial_sort) { [record_2.name, record_1.name] }

      describe 'sorting' do
        include_context 'results table setup'

        let(:default_sort_key) { 'title_sort' }
        let(:additional_browse_columns) do
          {
            2 => 'URI'
          }
        end
        let(:column_headers) { {'Title' => 'title_sort', 'URI' => 'uri'} }
        let(:primary_sort_expectations) do
          {
            'title_sort' => {
              asc: [record_2.name, record_1.name],
              desc: [record_1.name, record_2.name]
            },
            'uri' => uri_id_as_string_sort_expectations([record_1, record_2], ->(r) { r.name })
          }
        end

        it_behaves_like 'results table sorting'
      end
    end
  end

  describe 'default values' do
    let(:base_defaults) do
      {
        'container_profile_name_' => { value: '', type: :text },
        'container_profile_url_' => { value: '', type: :text },
        'container_profile_dimension_units_' => { value: 'Inches', type: :select },
        'container_profile_extent_dimension_' => { value: 'Height', type: :select },
        'container_profile_depth_' => { value: '', type: :text },
        'container_profile_height_' => { value: '', type: :text },
        'container_profile_width_' => { value: '', type: :text },
        'container_profile_stacking_limit_' => { value: '', type: :text },
        'container_profile_notes_' => { value: '', type: :text }
      }
    end

    let(:custom_defaults) do
      {
        'container_profile_name_' => { value: 'Default Box Name', type: :text },
        'container_profile_url_' => { value: 'https://example.com/default', type: :text },
        'container_profile_dimension_units_' => { value: 'Centimeters', type: :select },
        'container_profile_extent_dimension_' => { value: 'Width', type: :select },
        'container_profile_depth_' => { value: '10', type: :text },
        'container_profile_height_' => { value: '20', type: :text },
        'container_profile_width_' => { value: '30', type: :text },
        'container_profile_stacking_limit_' => { value: '5', type: :text },
        'container_profile_notes_' => { value: 'Default notes for container profile', type: :text }
      }
    end

    before(:each) do
      login_admin
      expect(page).to have_css('#user-menu-dropdown + .dropdown-menu', visible: false)
      within '.user-container' do
        click_on 'user-menu-dropdown'
        click_on 'Repository Preferences (admin)'
      end
      expect(page).to have_content('Edit these values to set your preferences for this repository.')
    end

    def set_prepopulate_records(enabled:)
      if enabled
        check('preference[defaults][default_values]')
      else
        uncheck('preference[defaults][default_values]')
      end
      click_on 'Save'
      expect(page).to have_content('Preferences updated')
    end

    def fill_default_values(values)
      values.each do |field_id, config|
        if config[:type] == :select
          select config[:value], from: field_id
        else
          fill_in field_id, with: config[:value]
        end
      end
    end

    def expect_field_values(values)
      aggregate_failures do
        values.each do |field_id, config|
          if config[:type] == :select
            expect(page).to have_select(field_id, selected: config[:value])
          else
            expect(page).to have_field(field_id, with: config[:value])
          end
        end
      end
    end

    context 'when Repository Preferences do not pre-populate records' do
      before do
        set_prepopulate_records(enabled: false)
      end

      it 'show the base defaults on the new container profile form' do
        visit('/container_profiles/new')
        expect_field_values(base_defaults)
      end
    end

    context 'when Repository Preferences do pre-populate records' do
      before do
        set_prepopulate_records(enabled: true)
      end

      context 'when default values are customized' do
        before do
          visit('/container_profiles/defaults')
          fill_default_values(custom_defaults)
          click_on 'Save'
          expect(page).to have_content('Defaults Updated')
        end

        it 'show the customized defaults on the new container profile form' do
          visit('/container_profiles/new')
          expect_field_values(custom_defaults)
        end
      end
    end
  end
end
