require 'spec_helper'
require 'rails_helper'

describe 'Spawning', js: true do

  before(:all) do
    @repo = create(:repo, repo_code: "spawning_test_#{Time.now.to_i}")
    set_repo(@repo)
    @accession = create(:json_accession,
      title: "Spawned Accession",
      extents: [build(:json_extent)],
      dates: [build(:json_date, date_type: "single")]
    )
    run_all_indexers
  end

  before(:each) do
    login_admin
    select_repository(@repo)
  end

  after(:each) do
    wait_for_ajax
    Capybara.reset_sessions!
  end

  xit "can spawn a resource component from an accession" do
    @resource = create(:resource)
    @parent = create(:json_archival_object,
                     resource: {'ref' => @resource.uri},
                     title: "Parent",
                     dates: [build(:json_date, date_type: "single")]
                    )
    PeriodicIndexer.new.run_index_round
    visit "/accessions/#{@accession.id}"
    find("#spawn-dropdown a").click
    find("#spawn-dropdown li:nth-of-type(3)").click
    find("input[value='#{@resource.uri}']").click
    find("#addSelectedButton").click
    click_link find("#archival_object_#{@parent.id} .title").text
    find("ul.largetree-dropdown-menu li:nth-of-type(2)").click
    find("#addSelectedButton").click
    expect(page.evaluate_script("location.href")).to include("resource_id=#{@resource.id}")
    expect(page.evaluate_script("location.href")).to include("archival_object_id=#{@parent.id}")
    expect(find("#archival_object_title_", visible: false).value()).to eq "Spawned Accession"
    find("#archival_object_level_ option[value='class']").click
    accession_link = find(:css, "form input[name='archival_object[accession_links][0][ref]']", :visible => false)
    expect(accession_link.value).to eq(@accession.uri)
    find(".save-changes button[type='submit']").click
    # wait for the form and tree container to load
    find("#tree-container")
    find(".record-pane")
    expect(find("div.indent-level-1 div.title")['title']).to eq "Parent"
    expect(find("div.indent-level-2 div.title")['title']).to eq "Spawned Accession"
    ref_id = find(".identifier-display").text
    visit "/accessions/#{@accession.id}"
    linked_component_ref_id = find("#accession_component_links_ table tbody tr td:nth-child(1)").text
    expect(linked_component_ref_id).to eq(ref_id)
  end

  xit "can create a digital object from a resource" do
    # make sure to enable the preference!
    visit "/preferences/#{@repo.id}/edit"
    find('#preference_defaults__digital_object_spawn_').check
    click_button('Save')

    # this backend fixture seems like a good test for note types
    @test_resource = create(:resource)
    fixture_dir = File.join(File.dirname(__FILE__), '..', '..', '..', 'backend', 'spec', 'fixtures', 'oai')
    @test_resource.update(ASUtils.json_parse(File.read(File.join(fixture_dir, 'resource.json'))))
    @test_resource.id_0 = "resource_#{Time.now}"
    @test_resource.ead_id = "ead_#{Time.now}"
    @test_resource.subjects = []
    @test_resource.linked_events = []
    @test_resource.linked_agents = []
    @test_resource.save

    visit "/resources/#{@test_resource.id}/edit"
    click_button('Add Digital Object')
    within(id: 'resource_instances_') do
      find(class: 'dropdown-toggle').click
      click_link('Create')
    end
    expect(page).to have_content('Create Digital Object')
    identifier = "do_test_#{Time.now}"
    fill_in('Identifier', with: identifier)
    click_button('Create and Link')

    within(id: 'resource_instances_') do
      find('.digital_object').click
      digital_object_tab = window_opened_by {click_link('View')}
      within_window digital_object_tab do
        expect(find('#resource_lang_materials_')).to have_content('Language of Materials Note')
        within(id: 'notes') do
          expect(page).to have_content('physical description note')
          expect(page).to have_content('dimensions note')
          expect(page).to have_content('bioghist note')
          expect(page).to have_content('scope and contents note')
          expect(page).to have_content('abstract note')
          expect(page).to have_content('existence and location of originals note')
          expect(page).to have_content('existence and location of copies note')
          expect(page).to have_content('related materials note')
          expect(page).to have_content('conditions governing access note')
          expect(page).to have_content('conditions governing use note')
          expect(page).to have_content('immediate source of acquisition note')
          expect(page).to have_content('custodial history note')
          expect(page).to have_content('physical characteristics and technical requirements note')
          expect(page).to have_content('preferred citation note')
          expect(page).to have_content('processing information note')

          expect(page).not_to have_content('separated materials note')
          expect(page).not_to have_content('arrangement note')
          expect(page).not_to have_content('other finding aids note')
          expect(page).not_to have_content('Accruals')
          expect(page).not_to have_content('Appraisal')

        end
      end
    end
  end

  xit 'can spawn a digital object from an accession' do
    # make sure to enable the preference!
    visit "/preferences/#{@repo.id}/edit"
    find('#preference_defaults__digital_object_spawn_').check
    click_button('Save')

    visit "/accessions/#{@accession.id}/edit"
    click_button('Add Digital Object')
    within(id: 'accession_instances_') do
      find(class: 'dropdown-toggle').click
      click_link('Create')
    end
    expect(page).to have_content('Create Digital Object')
    identifier = "do_test_#{Time.now}"
    fill_in('Identifier', with: identifier)
    click_button('Create and Link')

    within(id: 'accession_instances_') do
      find('.digital_object.initialised').click
      digital_object_tab = window_opened_by {click_link('View')}
      within_window digital_object_tab do
        expect(page).to have_content("Spawned Accession")
      end
    end
  end

end
