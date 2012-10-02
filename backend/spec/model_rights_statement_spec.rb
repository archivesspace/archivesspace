require 'spec_helper'

describe 'Rights Statement model' do

  before(:each) do
    make_test_repo
  end

  it "Supports creating a new rights statement" do
    rights_statement = RightsStatement.create_from_json(JSONModel(:rights_statement).
                                  from_hash({
                                              "identifier" => "abc123",
                                              "rights_type" => "intellectual_property",
                                              "ip_status" => "copyrighted",
                                              "jurisdiction" => "AU"
                                            }),
                                :repo_id => @repo_id)

    RightsStatement[rights_statement[:id]].identifier.should eq("abc123")
  end


  it "Enforces identifier uniqueness within a single repository" do
    repo_one = make_test_repo("RepoOne")
    repo_two = make_test_repo("RepoTwo")

    expect {
      RightsStatement.create_from_json(JSONModel(:rights_statement).
                                         from_hash({
                                                     "identifier" => "abc123",
                                                     "rights_type" => "intellectual_property",
                                                     "ip_status" => "copyrighted",
                                                     "jurisdiction" => "AU"
                                                   }),
                                       :repo_id => repo_one)
      RightsStatement.create_from_json(JSONModel(:rights_statement).
                                         from_hash({
                                                     "identifier" => "abc123",
                                                     "rights_type" => "intellectual_property",
                                                     "ip_status" => "copyrighted",
                                                     "jurisdiction" => "AU"
                                                   }),
                                       :repo_id => repo_one)
    }.to raise_error

    # No problems here
    RightsStatement.create_from_json(JSONModel(:rights_statement).
                                       from_hash({
                                                   "identifier" => "abc123",
                                                   "rights_type" => "intellectual_property",
                                                   "ip_status" => "copyrighted",
                                                   "jurisdiction" => "AU"
                                                 }),
                                     :repo_id => repo_two)
  end


  it "Enforces validation rules when rights_type is intellectual_property" do
    expect {
      RightsStatement.create_from_json(JSONModel(:rights_statement).
                                         from_hash({
                                                     "identifier" => "abc123",
                                                     "rights_type" => "intellectual_property",
                                                     "jurisdiction" => "AU"
                                                   }),
                                       :repo_id => @repo_id)
    }.to raise_error(JSONModel::ValidationException)

    expect {
      RightsStatement.create_from_json(JSONModel(:rights_statement).
                                         from_hash({
                                                     "identifier" => "abc123",
                                                     "rights_type" => "intellectual_property",
                                                     "ip_status" => "copyrighted",
                                                   }),
                                       :repo_id => @repo_id)
    }.to raise_error(JSONModel::ValidationException)


    # this is ok though
    RightsStatement.create_from_json(JSONModel(:rights_statement).
                                          from_hash({
                                                      "identifier" => "abc123",
                                                      "rights_type" => "intellectual_property",
                                                      "ip_status" => "copyrighted",
                                                      "jurisdiction" => "AU"
                                                    }),
                                        :repo_id => @repo_id)
  end


  it "Enforces validation rules when rights_type is statute" do
    expect {
      RightsStatement.create_from_json(JSONModel(:rights_statement).
                                         from_hash({
                                                     "identifier" => "abc123",
                                                     "rights_type" => "statute",
                                                     "statute_citation" => "This is where some statute details go.",
                                                   }),
                                       :repo_id => @repo_id)
    }.to raise_error(JSONModel::ValidationException)

    expect {
      RightsStatement.create_from_json(JSONModel(:rights_statement).
                                         from_hash({
                                                     "identifier" => "abc123",
                                                     "rights_type" => "statute",
                                                     "jurisdiction" => "AU"
                                                   }),
                                       :repo_id => @repo_id)
    }.to raise_error(JSONModel::ValidationException)

    # this is ok though
    RightsStatement.create_from_json(JSONModel(:rights_statement).
                                       from_hash({
                                                   "identifier" => "abc123",
                                                   "rights_type" => "statute",
                                                   "statute_citation" => "This is where some statute details go.",
                                                   "jurisdiction" => "AU"
                                                 }),
                                     :repo_id => @repo_id)
  end


  it "Enforces validation rules when rights_type is license" do
    expect {
      RightsStatement.create_from_json(JSONModel(:rights_statement).
                                         from_hash({
                                                     "identifier" => "abc123",
                                                     "rights_type" => "license",
                                                   }),
                                       :repo_id => @repo_id)
    }.to raise_error(JSONModel::ValidationException)

    # this is ok though
    RightsStatement.create_from_json(JSONModel(:rights_statement).
                                       from_hash({
                                                   "identifier" => "abc123",
                                                   "rights_type" => "license",
                                                   "license_identifier_terms" => "This is where some terms go.",
                                                 }),
                                     :repo_id => @repo_id)
  end

  it "Allows a rights statement to be created with an external document" do
    rights_statement = RightsStatement.create_from_json(JSONModel(:rights_statement).
                                                          from_hash({
                                                                      "identifier" => "abc123",
                                                                      "rights_type" => "intellectual_property",
                                                                      "ip_status" => "copyrighted",
                                                                      "jurisdiction" => "AU",

                                                                      "external_documents" => [
                                                                        {
                                                                          "title" => "My external document",
                                                                          "location" => "http://www.foobar.com",
                                                                        }
                                                                      ]
                                                          }),
                                                        :repo_id => @repo_id)

    RightsStatement[rights_statement[:id]].external_documents.length.should eq(1)
    RightsStatement[rights_statement[:id]].external_documents[0].title.should eq("My external document")
  end

end
