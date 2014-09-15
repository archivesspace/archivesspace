require 'spec_helper'

describe 'Repository model' do

  it "supports creating a new repository" do
    repo = Repository.create_from_json(JSONModel(:repository).from_hash(:repo_code => "TESTREPO",
                                                                        :name => "My new test repository"))

    repo = Repository.find(:repo_code => "TESTREPO")
    repo.name.should eq("My new test repository")
  end


  it "enforces ID uniqueness" do
    expect { Repository.create_from_json(JSONModel(:repository).from_hash(:repo_code => "TESTREPO",
                                                                          :name => "My new test repository")) }.to_not raise_error

    expect { Repository.create_from_json(JSONModel(:repository).from_hash(:repo_code => "TESTREPO",
                                                                          :name => "Another description")) }.to raise_error
  end


  it "enforces required fields" do

    expect { Repository.create_from_json(JSONModel(:repository).from_hash(:name => "My new test repository")) }.to raise_error

  end


  it "can transfer all records from one repository into another" do
    destination = make_test_repo("destination")
    source = make_test_repo("source")
    user_id = User[:username => RequestContext.get(:current_username)].id
    
    RequestContext.open(:repo_id => destination) do
      Preference.create_from_json(build(:json_preference),
                                  :user_id => user_id)
    end
    
    RequestContext.open(:repo_id => source) do
      Preference.create_from_json(build(:json_preference),
                                  :user_id => user_id)
    end

    records = []
    records << [Accession, create(:json_accession).id]
    records << [Resource, create(:json_resource).id]
    records << [DigitalObject, create(:json_digital_object).id]

    Repository[destination].assimilate(Repository[source])

    RequestContext.open(:repo_id => destination) do
      records.each do |model, id|
        model.this_repo[id].id.should eq(id)
      end
    end
  end


it "can identify and report conflicting identifiers" do
    destination = make_test_repo("destination")

    3.times do |i|
      create(:json_resource, :ead_id => "unique to this repository - #{i}")
    end

    source = make_test_repo("source")
    resource_ids = []
    3.times do |i|
      resource_ids << create(:json_resource, :ead_id => "unique to this repository - #{i}").id
    end

    expect {
      Repository[destination].assimilate(Repository[source])
    }.to raise_error {|e|
      e.should be_a(TransferConstraintError)
      e.conflicts.length.should eq(3)
      resource_ids.each do |resource_id|
        uri = "/repositories/#{source}/resources/#{resource_id}"
        e.conflicts[uri][0][:json_property].should eq(:ead_id)
      end
    }
  end

end
