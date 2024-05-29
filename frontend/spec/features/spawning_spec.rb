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

  it "can spawn a resource component from an accession" do
    set_repo(@repo)
    @resource = create(:resource)
    @parent = create(:json_archival_object,
                     resource: {'ref' => @resource.uri},
                     title: "Parent",
                     dates: [build(:json_date, date_type: "single")]
                    )
    run_indexer
    visit "/accessions/#{@accession.id}"
    find("#spawn-dropdown > button").click
    find("#spawn-dropdown .dropdown-menu li:nth-of-type(3)").click
    find("input[value='#{@resource.uri}']").click
    find("#addSelectedButton").click
    find("#archival_object_#{@parent.id} a.record-title").click
    find("ul.largetree-dropdown-menu li.dropdown-item .add-items-as-children").click
    find(".modal-footer button#addSelectedButton").click
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
    expect(find("#archival_object_#{@parent.id}  a.record-title ").text).to include "#{@parent.title}"
    spawned_archival_object_id = page.current_url.sub(/.*_/, "")
    expect(find("#archival_object_#{spawned_archival_object_id}  a.record-title ").text).to include "#{@accession.title}"
    ref_id = find(".identifier-display").text
    visit "/accessions/#{@accession.id}"
    linked_component_ref_id = find("#accession_component_links_ table tbody tr td:nth-child(1)").text
    expect(linked_component_ref_id).to eq(ref_id)
  end
end
