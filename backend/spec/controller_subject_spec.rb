require 'spec_helper'

describe 'Subject controller' do

  before(:each) do
    vocab = JSONModel(:vocabulary).from_hash("name" => "Cool Vocab")
    vocab.save
    @vocab_id = vocab.id
  end


  def create_subject
    subject = JSONModel(:subject).from_hash("term" => "1981 Heroes",
                                            "term_type" => "Cultural context",
                                            "vocabulary" => JSONModel(:vocabulary).uri_for(@vocab_id)
                                            )

    subject.save
  end


  it "lets you create a subject and get it back" do
    id = create_subject
    JSONModel(:subject).find(id).term.should eq("1981 Heroes")
  end
  
  
  it "fails when you try to update a subject that doesn't exist" do
    subject = JSONModel(:subject).from_hash("term" => "1981 Heroes",
                                            "term_type" => "Cultural context",
                                            "vocabulary" => JSONModel(:vocabulary).uri_for(@vocab_id)
                                            )
  
    subject.uri = "/subjects/999999"
  
    expect { subject.save }.to raise_error
  end


  it "supports updates" do
    id = create_subject

    subject = JSONModel(:subject).find(id)
    subject.term = "1981 Heroes FTW"
    subject.save

    JSONModel(:subject).find(id).term.should eq("1981 Heroes FTW")
  end


  it "knows its own URI" do
    id = create_subject
  
    JSONModel(:subject).find(id).uri.should eq("/subjects/#{id}")
  end

end
