require 'spec_helper'

describe 'Subject controller' do

  def create_subject
    post "/subjects", params = JSON({
                                     "term" => "1981 Heroes",
                                     "term_type" => "Cultural context"
                                  })

    last_response.should be_ok

    JSON(last_response.body)
  end


  it "lets you create an subject and get it back" do
    created = create_subject
    get "/subjects/#{created["id"]}"
    subject = JSON(last_response.body)
    subject["term"].should eq("1981 Heroes")
  end


  it "fails when you try to update a subject that doesn't exist" do
    post "/subjects/9999999", params = JSONModel(:subject).
      from_hash({
                  "term" => "1981 Heroes",
                  "term_type" => "Cultural context"
                }).to_json

    last_response.status.should eq(404)
    JSON(last_response.body)["error"].should eq("Subject not found")
  end


  it "supports updates" do
    created = create_subject

    # Update it
    post "/subjects/#{created['id']}", params = JSONModel(:subject).
      from_hash({
                  "term" => "1981 Heroes FTW",
                  "term_type" => "Cultural context"
                }).to_json


    get "subjects/#{created['id']}"
    subject = JSON(last_response.body)

    subject["term"].should eq("1981 Heroes FTW")
  end


  it "knows its own URI" do
    created = create_subject
    get "/subjects/#{created['id']}"
    subject = JSON(last_response.body)

    subject["uri"].should eq("/subjects/#{created['id']}")
  end

end
