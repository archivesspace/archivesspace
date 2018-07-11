# Tests here cover some of the endpoint functionality that isn't specific to any
# one controller.

require 'spec_helper'

describe 'REST interface' do

  it "requires view_repository access when performing GETs within a repo" do
    create(:repo, :repo_code => 'ARCHIVESSPACE')

    create(:user, :username => 'spongebob')
    create(:user, :username => 'mrkrabs')

    viewers = JSONModel(:group).all(:group_code => "repository-viewers").first
    archivists = JSONModel(:group).all(:group_code => "repository-archivists").first

    viewers.member_usernames = ["spongebob"]
    archivists.member_usernames = ["mrkrabs"]

    viewers.save
    archivists.save

    expect {
      as_test_user("spongebob") do
        JSONModel(:accession).from_hash("id_0" => "1234",
                                        "title" => "The accession title",
                                        "content_description" => "The accession description",
                                        "condition_description" => "The condition description",
                                        "accession_date" => "2012-05-03").save
      end
    }.to raise_error(AccessDeniedException)


    expect {
      as_test_user("mrkrabs") do
        JSONModel(:accession).from_hash("id_0" => "1234",
                                        "title" => "The accession title",
                                        "content_description" => "The accession description",
                                        "condition_description" => "The condition description",
                                        "accession_date" => "2012-05-03").save
      end
    }.to_not raise_error
  end


  it "handles bad pagination arguments" do
    create(:repo)

    nice_amount = 10
    AppConfig[:max_page_size] = nice_amount
    too_many = nice_amount + 1

    too_many.times {
       create(:json_accession)
    }

    expect {
      JSONModel(:accession).all(:page => 1, :page_size => -1)
    }.to raise_error(ArgumentError)

    expect {
      JSONModel(:accession).all(:page => -1)
    }.to raise_error(ArgumentError)

    expect {
      JSONModel(:accession).all(:modified_since => -1)
    }.to raise_error(ArgumentError)

    JSONModel(:accession).all(:page => 1, :page_size => too_many)['results'].size.should eq(nice_amount)

    JSONModel(:accession).all(:page => 10, :page_size => nice_amount)['results'].size.should eq(0)
  end


  it "reports an error if a bad value is given for a boolean argument" do
    create(:repo)

    id = create(:json_group).id

    expect {
      JSONModel(:group).find(id, 'with_members' => 'moo')
    }.to raise_error(RuntimeError)

    expect {
      JSONModel(:group).find(id, 'with_members' => nil)
    }.to_not raise_error

  end


  it "reports an error if a bad value is given for an integer argument" do
    create(:repo)

    id = create(:json_group).id

    expect {
      JSONModel(:group).find('not an integer')
    }.to raise_error(RuntimeError)
  end


  it "returns a list of all Endpoints" do
    expect {
      endpoint = RESTHelpers::Endpoint.all.first
      endpoint[:uri].nil?.should == false
      endpoint[:method].nil?.should == false
      endpoint[:returns].nil?.should == false
    }.to_not raise_error
  end


  it "supports querying Endpoints" do
    endpoint = RESTHelpers::Endpoint.get("/moo")

    endpoint['methods'].should eq([:get])
    endpoint['uri'].should eq('/moo')
  end

end
