require 'spec_helper'

describe 'Accession controller' do

  before(:each) do
    @repo = make_test_repo
  end


  def create_accession
    post "#{@repo}/accessions", params = JSON({
                                                "id_0" => "1234",
                                                "title" => "The accession title",
                                                "content_description" => "The accession description",
                                                "condition_description" => "The condition description",
                                                "accession_date" => "2012-05-03",
                                              })

    last_response.should be_ok

    JSON(last_response.body)
  end


  it "lets you create an accession and get it back" do
    created = create_accession
    get "#{@repo}/accessions/#{created["id"]}"
    acc = JSON(last_response.body)
    acc["title"].should eq("The accession title")
  end


  it "fails when you try to update an accession that doesn't exist" do
    post "#{@repo}/accessions/99999", params = JSONModel(:accession).
      from_hash({
                  "id_0" => "1234",
                  "title" => "The accession title",
                  "content_description" => "The accession description",
                  "condition_description" => "The condition description",
                  "accession_date" => "2012-05-03",
                }).to_json

    last_response.status.should eq(404)
    JSON(last_response.body)["error"].should eq("Accession not found")
  end


  it "warns about missing properties" do
    JSONModel::strict_mode(false)
    post "#{@repo}/accessions", params = JSON({"id_0" => "abcdef"})
    JSONModel::strict_mode(true)

    last_response.should be_ok
    created = JSON(last_response.body)

    known_warnings = ["accession_date", "condition_description", "content_description", "title"]

    (known_warnings - created["warnings"].keys).should eq([])
  end


  it "supports updates" do
    created = create_accession

    # Update it
    post "#{@repo}/accessions/#{created['id']}", params = JSONModel(:accession).
      from_hash({
                  "id_0" => "1234",
                  "id_1" => "5678",
                  "id_2" => "1234",
                  "title" => "The accession title",
                  "content_description" => "The accession description",
                  "condition_description" => "The condition description",
                  "accession_date" => "2012-05-03",
                }).to_json


    get "#{@repo}/accessions/#{created['id']}"
    acc = JSON(last_response.body)

    acc["id_1"].should eq("5678")
  end


  it "knows its own URI" do
    created = create_accession
    get "#{@repo}/accessions/#{created['id']}"
    acc = JSON(last_response.body)

    acc["uri"].should eq("#{@repo}/accessions/#{created['id']}")
  end

end
