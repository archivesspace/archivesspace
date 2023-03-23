require 'spec_helper'
require 'rails_helper'

describe 'Assessments', js: true do
  before(:all) do
    @repo = create(:repo, repo_code: "assessments_test_#{Time.now.to_i}")
    @other_repo = create(:repo, repo_code: "assessments_test_2_#{Time.now.to_i}")
    set_repo @repo

    @accession = create(:accession, title: 'Accession to assess')
    @resource = create(:resource, title: 'Resource to assess')
    @digital_object = create(:digital_object, title: 'Digital Object to assess')
    @archival_object = create(:archival_object, title: 'Archival Object to assess',
                                                resource: {
                                                  ref: @resource.uri
                                                })

    @archivist_user = create_user(@repo => ['repository-archivists'])
    @manager_user = create_user(@repo => ['repository-managers'], @other_repo => ['repository-managers'])
    run_indexer
  end

  before(:each) do
    allow(AppConfig).to receive(:[]).and_call_original
    allow(AppConfig).to receive(:[]).with(:allow_mixed_content_title_fields) { true }
  end

  it 'can add repository assessment attribute definitions' do
    # Add two ratings
    # TODO: fix the markup so we don't have multiple inputs with 'ratings__label' @id
    login repo: @repo
    find('.repo-container .btn.dropdown-toggle').click
    within('.repo-container .dropdown-menu') do
      click_link 'Manage Assessment Attributes'
    end
    within('#table_assessment_ratings') do
      find('.add-repo-attribute[data-type=rating]').click
      within('.repository-attributes tr:nth-child(1)') do
        fill_in(id: 'ratings__label', with: 'Danceability')
      end
      find('.add-repo-attribute[data-type=rating]').click
      within('.repository-attributes tr:nth-child(2)') do
        fill_in(id: 'ratings__label', with: 'Grooviness')
      end
    end
    # Add a format
    within('#table_assessment_formats') do
      find('.add-repo-attribute[data-type=format]').click
      fill_in id: 'formats__label', with: 'Vinyl Record'
    end
    # Add a conservation issue
    within('#table_assessment_conservation_issues') do
      find('.add-repo-attribute[data-type=conservation_issue]').click
      fill_in id: 'conservation_issues__label', with: 'Scratched'
    end

    within('li.form-actions') do
      find("form#assessment_attributes_form button[type='submit']").click
    end

    # Check they saved
    within('#table_assessment_ratings') do
      within('.repository-attributes tr:nth-child(1)') do
        expect(find(id: 'ratings__label').value).to eq('Danceability')
      end
      within('.repository-attributes tr:nth-child(2)') do
        expect(find(id: 'ratings__label').value).to eq('Grooviness')
      end
    end

    within('#table_assessment_formats') do
      expect(find(id: 'formats__label').value).to eq('Vinyl Record')
    end
    within('#table_assessment_conservation_issues') do
      expect(find(id: 'conservation_issues__label').value).to eq('Scratched')
    end
  end

  it 'can delete a repository attribute definition' do
    login repo: @repo
    find('.repo-container .btn.dropdown-toggle').click
    within('.repo-container .dropdown-menu') do
      click_link 'Manage Assessment Attributes'
    end
    within('#table_assessment_ratings .repository-attributes tr:nth-child(2)') do
      find('.remove-repo-attribute').click
    end
    within('li.form-actions') do
      find("form#assessment_attributes_form button[type='submit']").click
    end

    expect(page).to have_text 'Danceability'
    expect(page).to have_text 'Vinyl Record'
    expect(page).to have_text 'Scratched'

    expect(page).not_to have_text 'Grooviness'
  end

  it "check other repo doesn't have these attributes" do
    login user: @manager_user, repo: @other_repo
    find('.repo-container .btn.dropdown-toggle').click
    within('.repo-container .dropdown-menu') do
      click_link 'Manage Assessment Attributes'
    end
    expect(page).not_to have_text 'Danceability'
    expect(page).not_to have_text 'Vinyl Record'
    expect(page).not_to have_text 'Scratched'
    expect(page).not_to have_text 'Grooviness'

  end

  it 'can create an assessment with links to records and users' do
    login user: @archivist_user, repo: @repo
    click_link('Create')
    click_link('Assessment')

    # Assess the accession and archival object
    fill_in id: 'token-input-assessment_records_', with: 'Accession'
    find('li.token-input-dropdown-item2').click
    fill_in id: 'token-input-assessment_records_', with: 'Digital Object'
    find('li.token-input-dropdown-item2').click
    fill_in id: 'token-input-assessment_records_', with: 'Archival Object'
    find('li.token-input-dropdown-item2').click

    # # To be surveyed by the archivist
    fill_in id: 'token-input-assessment_surveyed_by_', with: @archivist_user.username
    find('li.token-input-dropdown-item2').click

    # # And reviewed by the repo manager
    find('#assessment_review_required_').click
    fill_in id: 'token-input-assessment_reviewer_', with: @manager_user.username
    find('li.token-input-dropdown-item2').click

    # # Save!
    within('li.form-actions') do
      find("form#assessment_form button[type='submit']").click
    end

    # # Check all were saved
    all('.breadcrumb-item a').last.click

    expect(
      find("#basic_information table:nth-child(1) tbody tr:nth-child(1)").text
    ).to include @accession.title
    expect(
      find("#basic_information table:nth-child(1) tbody tr:nth-child(2)").text
    ).to include @digital_object.title
    expect(
      find("#basic_information table:nth-child(1) tbody tr:nth-child(3)").text
    ).to include @archival_object.title


    expect(all('.token.agent_person').first.text).to eq @archivist_user.username
    expect(all('.token.agent_person').last.text).to eq @manager_user.username
  end

  it 'shows up in the listing' do
    run_indexer
    login repo: @repo
    click_link "Browse"
    click_link 'Assessments'

    listing_text = find('td.assessment_records').text
    [@resource, @archival_object, @accession, @digital_object].each do |record|
      expect(listing_text).to include record.title
    end

    surveyors_text = find('td.assessment_surveyors').text
    expect(surveyors_text).to include @archivist_user.username
  end

  it 'can save ratings and ratings notes' do
    login repo: @repo
    click_link "Browse"
    click_link 'Assessments'

    within "tbody .table-record-actions" do
      all("a").last.click
    end

    # Documentation Quality
    find("#assessment_ratings__0__value_[value='1']").click
    # Housing Quality
    find("#assessment_ratings__1__value_[value='2']").click
    # Intellectual Access (description)
    find("#assessment_ratings__2__value_[value='3']").click
    # Interest
    find("#assessment_ratings__3__value_[value='4']").click
    # Physical Access (arrangement)
    find("#assessment_ratings__4__value_[value='5']").click
    # Physical Condition
    find("#assessment_ratings__5__value_[value='1']").click
    # Reformatting Readiness
    find("#assessment_ratings__6__value_[value='2']").click
    # Danceability
    find("#assessment_ratings__7__value_[value='5']").click
    # Danceability Note
    all('.assessment-add-rating-note').last.click
    fill_in id: 'assessment_ratings__7__note_', with: 'Get your boogie on'

    within('li.form-actions') do
      find("form#assessment_form button[type='submit']").click
    end

    expect(evaluate_script("$('#assessment_ratings__0__value_:checked').val()")).to eq('1')
    expect(evaluate_script("$('#assessment_ratings__1__value_:checked').val()")).to eq('2')
    expect(evaluate_script("$('#assessment_ratings__2__value_:checked').val()")).to eq('3')
    expect(evaluate_script("$('#assessment_ratings__3__value_:checked').val()")).to eq('4')
    expect(evaluate_script("$('#assessment_ratings__4__value_:checked').val()")).to eq('5')
    expect(evaluate_script("$('#assessment_ratings__5__value_:checked').val()")).to eq('1')
    expect(evaluate_script("$('#assessment_ratings__6__value_:checked').val()")).to eq('2')
    expect(evaluate_script("$('#assessment_ratings__7__value_:checked').val()")).to eq('5')
    expect(evaluate_script("$('#assessment_ratings__7__note_').val()")).to eq('Get your boogie on')
  end

  it 'can save formats' do
    login repo: @repo
    click_link "Browse"
    click_link 'Assessments'

    within "tbody .table-record-actions" do
      all("a").last.click
    end

    # Audio Materials
    find('#assessment_formats__3__value_').click
    # Vinyl
    find('#assessment_formats__16__value_').click

    within('li.form-actions') do
      find("form#assessment_form button[type='submit']").click
    end

    expect(execute_script("return $('#assessment_formats__3__value_').is(':checked')")).to be_truthy
    expect(execute_script("return $('#assessment_formats__16__value_').is(':checked')")).to be_truthy
  end

  it 'can save conservation issues' do
    login repo: @repo
    click_link "Browse"
    click_link 'Assessments'

    within "tbody .table-record-actions" do
      all("a").last.click
    end

    # Potential Mold or Mold Damage
    find('#assessment_conservation_issues__5__value_').click
    # Scratched
    find('#assessment_conservation_issues__9__value_').click

    within('li.form-actions') do
      find("form#assessment_form button[type='submit']").click
    end

    expect(evaluate_script("$('#assessment_conservation_issues__5__value_').is(':checked')")).to be_truthy
    expect(evaluate_script("$('#assessment_conservation_issues__9__value_').is(':checked')")).to be_truthy
  end

  it 'has all the values in the readonly view' do
    run_indexer

    login repo: @repo
    click_link "Browse"
    click_link 'Assessments'

    within "tbody .table-record-actions" do
      all("a").first.click
    end

    # linked records
    expect(find('.token.accession').text).to match(/#{@accession.title}/)
    expect(find('.token.archival_object').text).to match(/#{@archival_object.title}/)
    expect(find('.token.digital_object').text).to match(/#{@digital_object.title}/)

    # linked agents
    expect(all('.token.agent_person').first.text).to eq @archivist_user.username
    expect(all('.token.agent_person').last.text).to eq @manager_user.username

    # ratings
    expect(evaluate_script("$('#rating_attributes_table').find('td:contains(\"Documentation Quality\")').parent().find('td')[1].innerText")).to eq('1')
    expect(evaluate_script("$('#rating_attributes_table').find('td:contains(\"Housing Quality\")').parent().find('td')[1].innerText")).to eq('2')
    expect(evaluate_script("$('#rating_attributes_table').find('td:contains(\"Intellectual Access\")').parent().find('td')[1].innerText")).to eq('3')
    expect(evaluate_script("$('#rating_attributes_table').find('td:contains(\"Interest\")').parent().find('td')[1].innerText")).to eq('4')
    expect(evaluate_script("$('#rating_attributes_table').find('td:contains(\"Physical Access\")').parent().find('td')[1].innerText")).to eq('5')
    expect(evaluate_script("$('#rating_attributes_table').find('td:contains(\"Physical Condition\")').parent().find('td')[1].innerText")).to eq('1')
    expect(evaluate_script("$('#rating_attributes_table').find('td:contains(\"Reformatting Readiness\")').parent().find('td')[1].innerText")).to eq('2')
    expect(evaluate_script("$('#rating_attributes_table').find('td:contains(\"Danceability\")').parent().find('td')[1].innerText")).to eq('5')
    expect(evaluate_script("$('#rating_attributes_table').find('td:contains(\"Research Value\")').parent().find('td')[1].innerText")).to eq('5') # Interest + Documentation Quality
    expect(evaluate_script("$('#rating_attributes_table').find('td:contains(\"Danceability\")').parent().find('td')[2].innerText")).to eq('Get your boogie on')

    # formats
    expect(all('#format_attributes li').first.text).to match /Audio Materials/
    expect(all('#format_attributes li').last.text).to match /Vinyl/

    # conservation issues
    expect(all('#conservation_issue_attributes li').first.text).to match /Potential Mold or Mold Damage/
    expect(all('#conservation_issue_attributes li').last.text).to match /Scratched/
  end

  it 'shows linked assessments on accession page' do
    login repo: @repo
    visit "/accessions/#{@accession.id}"
    expect(find('#linked_assessments #tabledSearchResults tbody tr td.assessment_surveyors').text).to include(@archivist_user.username)
  end

  it 'shows linked assessments on archival object page' do
    login repo: @repo
    visit "/resources/#{@resource.id}#tree::archival_object_#{@archival_object.id}"
    expect(find('#linked_assessments #tabledSearchResults tbody tr td.assessment_surveyors').text).to eq(@archivist_user.username)
  end

  it 'shows linked assessments on digital_object page' do
    login repo: @repo
    visit "/digital_objects/#{@digital_object.id}"
    expect(find('#linked_assessments #tabledSearchResults tbody tr td.assessment_surveyors').text).to eq(@archivist_user.username)
  end

  it 'shows linked assessments on agent_person page' do
    archivist_user_agent_id = JSONModel(:agent_person).id_for(JSONModel(:user).find(@archivist_user.id).agent_record['ref'])
    login repo: @repo
    visit "/agents/agent_person/#{archivist_user_agent_id}"
    expect(find('#linked_assessments_surveyed_by #tabledSearchResults tbody tr td.assessment_surveyors').text).to eq(@archivist_user.username)
  end

  it 'can add an external document to an Assessment' do
    login repo: @repo
    click_link "Browse"
    click_link 'Assessments'

    within "tbody .table-record-actions" do
      all("a").last.click
    end

    find('#assessment_external_documents_ .subrecord-form-heading .btn:not(.show-all)').click
    fill_in id: 'assessment_external_documents__0__title_', with: 'My URI document'
    fill_in id: 'assessment_external_documents__0__location_', with: 'http://archivesspace.org'

    within('li.form-actions') do
      find("form#assessment_form button[type='submit']").click
    end

    # check external documents
    expect(find('#assessment_external_documents_ .subrecord-form-wrapper').text).to include("Document Link")
  end

end
