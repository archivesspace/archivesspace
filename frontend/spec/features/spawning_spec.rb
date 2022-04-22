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

  it "can spawn a resource component from an accession" do
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
    find("#spawn-dropdown li:nth-of-type(3)").click
    find("input[value='#{@resource.uri}']").click
    find("#addSelectedButton").click
    find("input[value='#{@parent.uri}']").click
    find("#addSelectedButton").click
    expect(find("#archival_object_title_").value()).to eq "Spawned Accession"
    find("#archival_object_level_ option[value='class']").click
    find(".save-changes button[type='submit']").click
    expect(find("div.indent-level-1 div.title")['title']).to eq "Parent"
    expect(find("div.indent-level-2 div.title")['title']).to eq "Spawned Accession"
  end
end
