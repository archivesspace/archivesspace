# Tests here cover some of the endpoint functionality that isn't specific to any
# one controller.

require 'spec_helper'

describe 'REST interface' do

  it "Requires view_repository access when performing GETs within a repo" do
    make_test_repo("ARCHIVESSPACE")

    make_test_user("spongebob")
    make_test_user("mrkrabs")

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
    }.to_not raise_error(AccessDeniedException)
  end

end
