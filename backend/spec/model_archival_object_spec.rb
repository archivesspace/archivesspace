require 'spec_helper'

describe 'ArchivalObject model' do

  before(:each) do
    @repo = Repository.create(:repo_code => "TESTREPO",
                              :description => "My new test repository").id
  end


  def create_archival_object
    ArchivalObject.create_from_json(JSONModel(:archival_object).
                                    from_hash({ "id_0" => "abcd",
                                                "title" => "A new archival object"}),
                                    :repo_id => @repo)
  end


  it "Allows archival objects to be created" do
    ao = create_archival_object

    ArchivalObject[ao[:id]].title.should eq("A new archival object")
  end


  it "Prevents duplicate IDs " do
    ao = create_archival_object

    expect { create_archival_object }.to raise_error
  end


  it "Allows archival objects to be created with a subject" do
     subject = Subject.create_from_json(JSONModel(:subject).
                                            from_hash({
                                                        "term" => "1981 Heroes",
                                                        "term_type" => "Cultural context"
                                                      }))
     subject_ref = "/subjects/#{subject[:id]}"
     ao =  ArchivalObject.create_from_json(JSONModel(:archival_object).
                                   from_hash({ "id_0" => "abcd",
                                               "title" => "A new archival object",
                                               "subjects" => [subject_ref]}),
                                   :repo_id => @repo)

      ArchivalObject[ao[:id]].subjects[0].should eq(subject_ref)
  end

end
