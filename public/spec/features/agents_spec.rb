require 'spec_helper'
require 'rails_helper'

describe 'Agents', js: true do
  it 'should be able to see all agents' do
    visit('/agents')
    within all('.col-sm-12')[0] do
      expect(page).to have_content("Showing Names:")
    end
  end

  it 'displays agent page' do
    visit('/')
    click_link 'Names'

    aggregate_failures 'supporting accessibility by not skipping heading levels in agents listing' do
      expect(page).to be_axe_clean.checking_only :'heading-order'
    end

    click_link 'Linked Agent 1' # prefer this agent because it's a "full" record
    expect(current_path).to match(/agents\/people\/\d+/)
    expect(page).to have_content('Linked Agent 1')

    aggregate_failures 'supporting accessibility by not skipping heading levels while viewing a specific agent' do
      expect(page).to be_axe_clean.checking_only :'heading-order'
    end
  end

  it 'does not highlight repository uri' do
    visit('/')

    click_on 'Repositories'
    click_on 'Test Repo 1'
    find('#whats-in-container form .btn.btn-default.agent').click

    expect(page).to_not have_text Pathname.new(current_path).parent.to_s
  end
end

describe 'Agent with multiple name forms', js: true do
  before(:all) do
    @now = Time.now.to_i

    auth_use_date = {
      'date_label' => 'usage',
      'date_type_structured' => 'range',
      'structured_date_range' => {
        'begin_date_expression' => '2000',
        'end_date_expression' => '2005'
      }
    }

    alias_one_use_date = {
      'date_label' => 'usage',
      'date_type_structured' => 'range',
      'structured_date_range' => {
        'begin_date_expression' => '2006',
        'end_date_expression' => '2010'
      }
    }

    alias_two_use_date = {
      'date_label' => 'usage',
      'date_type_structured' => 'single',
      'structured_date_single' => {
        'date_expression' => '2011',
        'date_role' => 'begin'
      }
    }

    @agent_with_multiple_names = create(
      :agent_person,
      names: [
        build(
          :name_person,
          primary_name: "Authoritative Name #{@now}",
          authority_id: "auth_id_#{@now}",
          is_display_name: true,
          authorized: true,
          use_dates: [auth_use_date]
        ),
        build(
          :name_person,
          primary_name: "Alias One #{@now}",
          use_dates: [alias_one_use_date]
        ),
        build(
          :name_person,
          primary_name: "Alias Two #{@now}",
          use_dates: [alias_two_use_date]
        )
      ],
      publish: true
    )
    run_indexers
  end

  after(:all) do
    @agent_with_multiple_names&.delete
  end

  it 'displays name usage dates correctly' do
    visit('/agents')

    find('a.record-title', text: /Authoritative Name/, match: :first).click

    expect(current_path).to match(/agents\/people\/\d+/)
    expect(page).to have_content("Authoritative Name")

    within('#sidebar') do
      alias_one_item = find('li', text: /Alias One #{@now}/)
      expect(alias_one_item).to have_content('Usage: 2006 - 2010')

      alias_two_item = find('li', text: /Alias Two #{@now}/)
      expect(alias_two_item).to have_content('Usage: 2011')
    end

    within('[data-test="main-content-agent-dates"]') do
      # Check authoritative name and dates appear in main section
      expect(page).to have_content('Usage:')
      expect(page).to have_content('2000 - 2005')

      # Check alias dates do NOT appear in the main dates section
      expect(page).not_to have_content('2006 - 2010')
      expect(page).not_to have_content('2011')
    end
  end
end
