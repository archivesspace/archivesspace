# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Keyboard Shortcuts', js: true do
  include KeyboardShortcutHelpers

  before(:all) { @repo = create(:repo, repo_code: "keyboard_shortcuts_test_#{Time.now.to_i}") }

  let(:now) { Time.now.to_i }

  context 'Dashboard' do
    let(:dashboard_path) { '/' }

    before { login_admin_and_select_repository(@repo) }

    it_behaves_like 'using the global shortcuts', path: :dashboard_path
  end

  describe 'on record edit pages' do
    before do
      set_repo @repo
      login_admin_and_select_repository(@repo)
    end

    context 'Accessions' do
      let(:accession) { create(:accession, title: "Accession #{now}") }
      let(:edit_path) { "/accessions/#{accession.id}/edit" }
      let(:readonly_path) { "/accessions/#{accession.id}" }

      it_behaves_like 'using the global shortcuts'
      it_behaves_like 'saving the record with the save shortcut',
                      field: 'accession_title_',
                      saved_message: ->(title) { "Accession #{title} updated" }
      it_behaves_like 'closing the record to its readonly view', field: 'accession_title_'

      it 'does not save the record with Ctrl+S alone' do
        visit edit_path
        fill_in 'accession_title_', with: "UPDATED #{now}"
        page.driver.browser.action.key_down(:control).send_keys('s').key_up(:control).perform

        expect(page).not_to have_content("Accession UPDATED #{now} updated")
        expect(page).to have_field('accession_title_', with: "UPDATED #{now}")
      end

      it 'does not close the record with Ctrl+X alone' do
        visit edit_path
        page.driver.browser.action.key_down(:control).send_keys('x').key_up(:control).perform

        expect(page).to have_current_path(edit_path)
      end

      it 'saves neither the new record in a linker "create" modal nor the record behind it' do
        visit edit_path
        click_on 'Add Subject'
        find('#accession_subjects_ .dropdown-toggle').click
        within('#dropdownMenuSubjects') { click_on 'Create' }

        expect(page).to have_css('.modal.show #createAndLinkButton')
        fill_in 'Term', with: "Subject term #{now}"

        start_counting_form_submissions
        press_save_shortcut

        expect(form_submission_count).to eq(0)
        expect(page).to have_css('.modal.show #createAndLinkButton')
        expect(page).to have_field('Term', with: "Subject term #{now}")
        expect(page).to have_current_path(edit_path)

        within('.modal.show') { click_on 'Cancel' }
        expect(page).not_to have_css('.modal.show')
        expect(page).not_to have_text(/Accession .+ updated/)
      end
    end

    context 'Agents' do
      let(:agent) { create(:agent_person) }
      let(:edit_path) { "/agents/agent_person/#{agent.id}/edit" }
      let(:readonly_path) { "/agents/agent_person/#{agent.id}" }

      it_behaves_like 'using the global shortcuts'
      it_behaves_like 'saving the record with the save shortcut',
                      field: 'agent_names__0__primary_name_',
                      saved_message: 'Agent Saved'
      it_behaves_like 'closing the record to its readonly view', field: 'agent_names__0__primary_name_'

      it 'shows validation warnings for confirmation instead of saving' do
        visit '/agents/agent_person/new'
        fill_in 'agent_names__0__authority_id_', with: "Authority ID #{now}"
        fill_in 'agent_names__0__primary_name_', with: "Agent Name #{now}"
        select 'Local', from: 'agent_names__0__rules_'

        press_save_shortcut

        element = find('.alert.alert-warning.with-hide-alert')
        expect(element.text).to eq "Source - is required if there is an 'Authority ID'"
        expect(page).to have_button('Save Anyway')
        expect(page).not_to have_text('Agent Created')
      end
    end

    context 'Subjects' do
      let(:subject_record) { create(:subject) }
      let(:edit_path) { "/subjects/#{subject_record.id}/edit" }
      let(:readonly_path) { "/subjects/#{subject_record.id}" }

      it_behaves_like 'using the global shortcuts'
      it_behaves_like 'saving the record with the save shortcut',
                      field: 'subject_terms__0__term_',
                      saved_message: 'Subject Saved'
      it_behaves_like 'closing the record to its readonly view', field: 'subject_terms__0__term_'
    end

    context 'Events' do
      let(:event) { create(:event, date: build(:date, date_type: 'single', end: nil)) }
      let(:edit_path) { "/events/#{event.id}/edit" }
      let(:readonly_path) { "/events/#{event.id}" }

      it_behaves_like 'using the global shortcuts'
      it_behaves_like 'saving the record with the save shortcut',
                      field: 'event_outcome_note_',
                      saved_message: 'Event Saved'
      it_behaves_like 'closing the record to its readonly view', field: 'event_outcome_note_'
    end

    context 'Locations' do
      let(:location) { create(:location) }
      let(:edit_path) { "/locations/#{location.id}/edit" }
      let(:readonly_path) { "/locations/#{location.id}" }

      it_behaves_like 'using the global shortcuts'
      it_behaves_like 'saving the record with the save shortcut',
                      field: 'location_building_',
                      saved_message: 'Location Saved'
      it_behaves_like 'closing the record to its readonly view', field: 'location_building_'
    end

    context 'Top Containers' do
      let(:top_container) { create(:top_container) }
      let(:edit_path) { "/top_containers/#{top_container.id}/edit" }
      let(:readonly_path) { "/top_containers/#{top_container.id}" }

      it_behaves_like 'using the global shortcuts'
      it_behaves_like 'saving the record with the save shortcut',
                      field: 'top_container_indicator_',
                      saved_message: 'Top Container Updated'
      it_behaves_like 'closing the record to its readonly view', field: 'top_container_indicator_'
    end

    context 'Assessments' do
      let(:assessment) do
        create(:json_assessment,
               'records' => [{ 'ref' => create(:resource).uri }],
               'surveyed_by' => [{ 'ref' => create(:agent_person).uri }],
               'survey_begin' => '2025-01-01',
               'survey_end' => '2025-01-02',
               'review_required' => false,
               'sensitive_material' => false)
      end
      let(:edit_path) { "/assessments/#{assessment.id}/edit" }
      let(:readonly_path) { "/assessments/#{assessment.id}" }

      it_behaves_like 'using the global shortcuts'
      it_behaves_like 'saving the record with the save shortcut',
                      field: 'assessment_purpose_',
                      saved_message: 'Assessment Updated'
      it_behaves_like 'closing the record to its readonly view', field: 'assessment_purpose_'
    end

    context 'Container Profiles' do
      let(:container_profile) { create(:container_profile) }
      let(:edit_path) { "/container_profiles/#{container_profile.id}/edit" }
      let(:readonly_path) { "/container_profiles/#{container_profile.id}" }

      it_behaves_like 'using the global shortcuts'
      it_behaves_like 'saving the record with the save shortcut',
                      field: 'container_profile_name_',
                      # Saving redirects to the readonly view without a success message.
                      lands_on_readonly_view: true,
                      shows_value: true
      it_behaves_like 'closing the record to its readonly view', field: 'container_profile_name_'
    end

    context 'Location Profiles' do
      let(:location_profile) { create(:location_profile) }
      let(:edit_path) { "/location_profiles/#{location_profile.id}/edit" }
      let(:readonly_path) { "/location_profiles/#{location_profile.id}" }

      it_behaves_like 'using the global shortcuts'
      it_behaves_like 'saving the record with the save shortcut',
                      field: 'location_profile_name_',
                      # Saving redirects to the readonly view without a success message.
                      lands_on_readonly_view: true,
                      shows_value: true
      it_behaves_like 'closing the record to its readonly view', field: 'location_profile_name_'
    end

    context 'Repositories' do
      let(:repository) { create(:repo) }
      let(:edit_path) { "#{repository.uri}/edit" }
      let(:readonly_path) { repository.uri }

      it_behaves_like 'using the global shortcuts'
      it_behaves_like 'saving the record with the save shortcut',
                      field: 'repository_repository__name_',
                      saved_message: 'Repository Saved'
      it_behaves_like 'closing the record to its readonly view', field: 'repository_repository__name_'
    end

    context 'Users' do
      let(:user) { create_user }
      let(:edit_path) { "/users/#{user.id}/edit" }
      let(:readonly_path) { "/users/#{user.id}" }

      it_behaves_like 'using the global shortcuts'
      it_behaves_like 'saving the record with the save shortcut',
                      field: 'user_name_',
                      saved_message: 'User Saved'
      it_behaves_like 'closing the record to its readonly view', field: 'user_name_'
    end

    context 'Custom Report Templates' do
      let(:template) do
        create(:json_custom_report_template,
               name: "Template #{now} #{SecureRandom.hex(2)}",
               data: { custom_record_type: 'accession', fields: { title: { include: '1' } } }.to_json)
      end
      let(:edit_path) { "/custom_report_templates/#{template.id}/edit" }
      let(:readonly_path) { "/custom_report_templates/#{template.id}" }

      it_behaves_like 'using the global shortcuts'
      it_behaves_like 'saving the record with the save shortcut',
                      field: 'custom_report_template_name_',
                      saved_message: 'Custom Report Template updated'
      it_behaves_like 'closing the record to its readonly view', field: 'custom_report_template_name_'
    end

    context 'Groups' do
      let(:group) { create(:json_group) }
      let(:edit_path) { "/groups/#{group.id}/edit" }

      it_behaves_like 'using the global shortcuts'
      it_behaves_like 'saving the record with the save shortcut',
                      field: 'group_description_',
                      shows_value: true
      it_behaves_like 'closing a form that has no readonly view', lands_on: '/groups'
    end

    context 'Preferences' do
      let(:edit_path) { '/preferences/0/edit?repo=true' }

      it_behaves_like 'using the global shortcuts'
      it_behaves_like 'saving the record with the save shortcut',
                      field: 'preference_defaults__accession_browse_column_1_',
                      value: 'Acquisition Type',
                      select: true,
                      saved_message: 'Preferences updated'
      it_behaves_like 'closing a form that has no readonly view', lands_on: %r{\A/preferences/\d+\z}
    end

    context 'OAI-PMH Settings' do
      let(:edit_path) { '/oai_config/edit' }

      it_behaves_like 'using the global shortcuts'
      it_behaves_like 'saving the record with the save shortcut',
                      field: 'oai_config_oai_admin_email_',
                      value: "shortcut-#{Time.now.to_i}@example.com",
                      saved_message: 'OAI-PMH settings successfully updated!'
      # There is no route for /oai_config.
      it_behaves_like 'closing a form that has no readonly view', lands_on: '/oai_config'
    end

    context 'Assessment Attributes' do
      let(:edit_path) { '/assessment_attributes' }

      it_behaves_like 'using the global shortcuts'

      it 'saves the record with Shift+Ctrl+S' do
        visit edit_path
        find('.add-repo-attribute[data-type=rating]').click
        find('#ratings__label', match: :first).fill_in with: "Shortcut rating #{now}"

        press_save_shortcut

        expect(page).to have_css('.alert-success', text: 'Assessment Attributes updated')
        expect(page).to have_field('ratings[][label]', with: "Shortcut rating #{now}")
      end

      it_behaves_like 'reloading a form whose URL has no /edit with the close shortcut'
    end
  end

  describe 'on Infinite Tree edit pages' do
    context 'Resources' do
      config = InfiniteTreeHierarchyConfigs::INTEGRATION[:resources]
      include_context 'infinite tree integration hierarchy setup', config

      it_behaves_like 'using keyboard shortcuts on an Infinite Tree edit page', config

      it 'starts only one save when triggered again while a save is in flight' do
        visit "#{edit_path}#{child_record_hash}"
        wait_for_infinite_tree_loaded
        fill_in config[:child_post_save_field], with: "Shortcut Child #{now}"

        start_counting_form_submissions
        # Two calls in one script, so the second runs before the first save can
        # finish; the first click disables Save and the second must be ignored.
        page.execute_script('AS.clickRecordFormSaveButton(); AS.clickRecordFormSaveButton();')

        expect(form_submission_count).to eq(1)
        expect(page).to have_css('#infinite-tree-record-pane .alert-success', text: "Shortcut Child #{now}")
        expect(page).not_to have_css('#infinite-tree-record-pane .alert-danger')
      end
    end

    context 'Digital Objects' do
      config = InfiniteTreeHierarchyConfigs::INTEGRATION[:digital_objects]
      include_context 'infinite tree integration hierarchy setup', config

      it_behaves_like 'using keyboard shortcuts on an Infinite Tree edit page', config
    end

    context 'Classifications' do
      config = InfiniteTreeHierarchyConfigs::INTEGRATION[:classifications]
      include_context 'infinite tree integration hierarchy setup', config

      it_behaves_like 'using keyboard shortcuts on an Infinite Tree edit page', config
    end
  end
end
