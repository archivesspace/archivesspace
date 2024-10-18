# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Repositories', js: true do

  before(:all) do
    # the edit repo page has two save buttons
    @prev_match_strat = Capybara.match
    Capybara.match = :first

    @repo = create(:repo, repo_code: "repo_repositories_spec_test_#{Time.now.to_i}",
      publish: true)
    @repo2 = create(:repo, repo_code: "repo_repositories_spec_test2_#{Time.now.to_i}",
      publish: true)
    set_repo(@repo)

    run_indexer

    @test_repo_code_1 = "repo_repositories_spec_test_create_#{Time.now.to_i}"
    @test_repo_name_1 = "test create repository 1 - #{Time.now.utc}"
    @test_repo_code_2 = "repo_repositories_spec_test_create2_#{Time.now.to_i}"
    @test_repo_name_2 = "test create repository 2 - #{Time.now.utc}"
  end

  before(:each) do
    login_admin
  end

  after(:all) do
    Capybara.match = @prev_match_strat
  end

  it 'flags errors when creating a repository with missing fields' do
    click_button('System')
    click_link('Manage Repositories')
    click_link('Create Repository')
    fill_in(id: 'repository_repository__name_', with: 'missing field test')
    within('#archivesSpaceSidebar') do
      find("button[type='submit']").click
    end
    expect(page).to have_content('Repository Short Name - Property is required but was missing')
  end

  it 'can create a repository' do
    click_button('System')
    click_link('Manage Repositories')
    click_link('Create Repository')
    fill_in(id: 'repository_repository__repo_code_', with: @test_repo_code_1)
    fill_in(id: 'repository_repository__name_', with: @test_repo_name_1)
    within('#archivesSpaceSidebar') do
      find("button[type='submit']").click
    end
    expect(page).to have_content('Repository Created')
  end

  it 'can add telephone numbers' do
    visit("#{@repo.uri}/edit")

    click_button('Add Telephone Number')
    fill_in(id: 'repository_agent_representation__agent_contacts__0__telephones__0__number_',
        with: '555-555-5555')
    fill_in(id: 'repository_agent_representation__agent_contacts__0__telephones__0__ext_',
        with: '5678')
    select('business',
        from: 'repository_agent_representation__agent_contacts__0__telephones__0__number_type_')
    click_button('Add Telephone Number')
    fill_in(id: 'repository_agent_representation__agent_contacts__0__telephones__1__number_',
        with: '123-456-7890')
    within('#archivesSpaceSidebar') do
      find("button[type='submit']").click
    end

    expect(page).to have_content('Repository Saved')
    expect(page).to have_content('business')
    expect(page).to have_content('555-555-5555')
    expect(page).to have_content('5678')
    expect(page).to have_content('123-456-7890')
  end

  it 'cannot delete contact info subrecord from a repository record' do
    visit("#{@repo.uri}/edit")

    expect(page).to have_content('Contact Name')
    expect(page).not_to have_field('//*[@id="repository_agent_representation__agent_contacts__0_"]/a')
  end

  it 'can add a an email signature to a repo record' do
    visit("#{@repo.uri}/edit")
    sig = 'Yours Truly, A. Space'
    fill_in(id: 'repository_agent_representation__agent_contacts__0__email_signature_', with: sig)
    within('#archivesSpaceSidebar') do
      find("button[type='submit']").click
    end

    expect(page).to have_content('Repository Saved')
    expect(page).to have_content(sig)
  end

  it 'will add a new contact name on save if the existing one is deleted' do
    visit("#{@repo.uri}/edit")
    fill_in('Contact Name', with: '')
    within('#archivesSpaceSidebar') do
      find("button[type='submit']").click
    end

    expect(page).to have_content('Repository Saved')
    expect(
      find(:xpath,
        '//*[@id="repository_agent_representation__agent_contacts__0_"]/div/div[1]/div').text
    ).to eq @repo.name
  end

  it 'will only display the first contact record if there are multiple' do
    agent_id = JSONModel(:agent_corporate_entity).id_for @repo2['agent_representation']['ref']
    visit "/agents/agent_corporate_entity/#{agent_id}/edit"
    click_button('Add Contact')
    field = find('#agent_corporate_entity_contact_details li:last-child input[id$="__name_"]')
    field.fill_in(with: 'This is not the contact you are looking for')
    find('button', exact_text: "Save").click
    expect(page).to have_content('Agent Saved')
    visit(@repo2.uri)
    expect(page).not_to have_content('This is not the contact you are looking for')
  end

  it 'does not display embedded note subrecord on repo page' do
    visit '#{@repo.uri}'
    expect(page).not_to have_content('Contact Note')
  end

  it 'cannot delete the currently selected repository' do
    select_repository(@repo)
    visit '#{@repo.uri}/edit'
    expect(page).not_to have_css('button.delete-repository')
  end

  it 'can delete a repository' do
    throwaway_repo = create(:repo, repo_code: "throwaway_#{Time.now.to_i}")
    set_repo(throwaway_repo)

    # make sure it contains some stuff
    create(:accession)
    create(:resource)

    run_indexer

    visit("#{throwaway_repo.uri}/edit")
    click_button('Delete')
    within('#confirmChangesModal') do
      # TODO: this id is a typo and should probably be corrected
      fill_in('deleteRepoConfim', with: throwaway_repo.repo_code)
      click_button('confirmButton')
    end

    expect(page).to have_content('Repository Deleted')
  end

  it 'strips out quotes from confirmation when deleting a repository' do
    throwaway_repo = create(:repo, repo_code: "delete'me_#{Time.now.to_i}")
    set_repo(throwaway_repo)
    scrubbed_repo_code = throwaway_repo.repo_code.gsub("'", "")
    visit("#{throwaway_repo.uri}/edit")
    click_button('Delete')
    expect(page).to have_content(scrubbed_repo_code)
    fill_in(id: 'deleteRepoConfim', with: scrubbed_repo_code)
    click_button('confirmButton')
    expect(page).to have_content('Repository Deleted')
  end

  it 'can create a second repository' do
    visit '/repositories/new'
    fill_in(id: 'repository_repository__repo_code_', with: @test_repo_code_2)
    fill_in(id: 'repository_repository__name_', with: @test_repo_name_2)
    within('#archivesSpaceSidebar') do
      find("button[type='submit']").click
    end

    expect(page).to have_content('Repository Created')
  end

  it 'can select either of the created repositories' do
    visit '/'
    select_repository(@repo2)
    expect(page).to have_content("The Repository #{@repo2.repo_code} is now active")
    select_repository(@repo)
    expect(page).to have_content("The Repository #{@repo.repo_code} is now active")
  end

  it 'automatically refreshes the repository list when a new repo gets added' do
    repo = create(:repo)
    MemoryLeak::Resources.refresh(:repository)
    page.refresh
    click_button('Select Repository')
    expect(find('select', id: 'id')).to have_content(repo.repo_code)
  end

  it 'will only show the Set Order in Public Interface button when configured as such' do
    visit '/repositories'
    expect(page).not_to have_content('Set Order in Public Interface')

    allow(AppConfig).to receive(:[]).and_call_original
    allow(AppConfig).to receive(:[]).with(:pui_repositories_sort) { :position }
    page.refresh
    expect(page).to have_content('Set Order in Public Interface')
  end

end
