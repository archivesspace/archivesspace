require 'spec_helper'
require 'rails_helper'

describe 'Spawning', js: true do

  before(:all) do
    @repo = create(:repo, repo_code: "spawning_test_#{Time.now.to_i}")
    set_repo(@repo)
  end

  before(:each) do
    login_admin
    select_repository(@repo)
  end

  after(:each) do
    wait_for_ajax
    Capybara.reset_sessions!
  end

  # This functionality is working in the UI, but the spec is still failing. It is possible to spawn a resource from an accession, but this is failing because the navigation within the test is working incorrectly- in the modal, the resource is not being added as a child, even though i have no issue doing this in the UI.
  it "can spawn a resource component from an accession"  do#, :skip => "UPGRADE skipping for green CI"
    @accession = create(:json_accession,
                        title: "Spawned Accession",
                        extents: [build(:json_extent)],
                        dates: [build(:json_date)]
                       )
    @resource = create(:resource)
    @parent = create(:json_archival_object,
                     :resource => {'ref' => @resource.uri},
                     :title => "Parent")
    PeriodicIndexer.new.run_index_round
    visit "/accessions/#{@accession.id}"
    find("#spawn-dropdown a").click
    find("#spawn-dropdown li.dropdown-item:nth-of-type(3)").click
    find("input[value='#{@resource.uri}']").click
    find("#addSelectedButton").click
    find("#archival_object_#{@parent.id} a.record-title").click
    find("ul.largetree-dropdown-menu li.dropdown-item a.add-items-as-children").click
    find(".modal-footer button#addSelectedButton").click
    expect(page.evaluate_script("location.href")).to include("resource_id=#{@resource.id}")
    expect(find("#archival_object_title_").value()).to eq "Spawned Accession"
    expect(page.evaluate_script("location.href")).to include("accession_id=#{@accession.id}")
    find("#archival_object_level_ option[value='class']").click
    accession_link = find(:css, "form input[name='archival_object[accession_links][0][ref]']", :visible => false)
    expect(accession_link.value).to eq(@accession.uri)
    find(".save-changes button[type='submit']").click
    # wait for the form and tree container to load
    find("#tree-container")
    find(".record-pane")
    
    expect(find("#archival_object_#{@parent.id}  a.record-title ").text).to include "#{@parent.title}"
    expect(find("#archival_object_#{@accession.id}  a.record-title ").text).to include "#{@accession.title}"
    ref_id = find(".identifier-display").text
    visit "/accessions/#{@accession.id}"
    linked_component_ref_id = find("#accession_component_links_ table tbody tr td:nth-child(1)").text
    expect(linked_component_ref_id).to eq(ref_id)
  end
end
