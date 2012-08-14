require 'spec_helper'

describe 'Archival Object controller' do

  before(:each) do
    make_test_repo
  end


  def create_archival_object(opts = {})
    ao = JSONModel(:archival_object).from_hash("id_0" => "1234",
                                               "id_1" => "5678",
                                               "title" => "The archival object title")
    ao.update(opts)
    ao.save
  end


  it "lets you create an archival object and get it back" do
    created = create_archival_object
    JSONModel(:archival_object).find(created).title.should eq("The archival object title")
  end


  it "lets you create an archival object with a parent" do
    collection = JSONModel(:collection).from_hash("title" => "a collection")
    collection.save

    created = create_archival_object("collection" => collection.uri)

    create_archival_object("id_0" => "4567",
                           "collection" => collection.uri,
                           "title" => "child archival object",
                           "parent" => "#{@repo}/archival_objects/#{created}")

    get "#{@repo}/archival_objects/#{created}/children"
    last_response.should be_ok

    children = JSON(last_response.body)
    children[0]["title"].should eq("child archival object")
  end


  it "warns about missing properties" do
    JSONModel::strict_mode(false)
    ao = JSONModel(:archival_object).from_hash("id_0" => "abc")
    ao.save

    known_warnings = ["title"]

    (known_warnings - ao._exceptions[:warnings].keys).should eq([])
    JSONModel::strict_mode(true)
  end


  it "handles updates for an existing archival object" do
    created = create_archival_object

    ao = JSONModel(:archival_object).find(created)
    ao.title = "A brand new title"
    ao.save

    JSONModel(:archival_object).find(created).title.should eq("A brand new title")
  end


  it "treats updates as being replaces, not additions" do
    created = create_archival_object

    ao = JSONModel(:archival_object).find(created)
    ao.id_1 = nil
    ao.save

    JSONModel(:archival_object).find(created).id_1.should be_nil

  end


  it "lets you create an archival object with a subject" do
    subject = JSONModel(:subject).from_hash("term" => "a test subject",
                                            "term_type" => "Cultural context")
    subject.save

    created = create_archival_object("id_0" => "4567",
                                     "subjects" => [subject.uri],
                                     "title" => "child archival object")

    JSONModel(:archival_object).find(created).subjects[0].should eq(subject.uri)
  end


  it "can resolve subjects for you" do
    subject = JSONModel(:subject).from_hash("term" => "a test subject",
                                            "term_type" => "Cultural context")
    subject.save

    created = create_archival_object("id_0" => "4567",
                                     "subjects" => [subject.uri],
                                     "title" => "child archival object")


    ao = JSONModel(:archival_object).find(created, "resolve[]" => "subjects")

    ao.subjects[0]["term"].should eq("a test subject")
  end



end
