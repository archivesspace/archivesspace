require 'spec_helper'

describe 'Subject controller' do

  before(:each) do
    vocab = JSONModel(:vocabulary).from_hash("name" => "Cool Vocab",
                                             "ref_id" => "coolid"
                                             )
    vocab.save
    @vocab_id = vocab.id
  end


  def create_subject
    vocab_uri = JSONModel(:vocabulary).uri_for(@vocab_id)
    subject = JSONModel(:subject).from_hash("terms" => [{"term" => "1981 Heroes", "term_type" => "Cultural context", "vocabulary" => vocab_uri}],
                                            "vocabulary" => vocab_uri
                                            )

    subject.save
  end


  it "lets you create a subject and get it back" do
    id = create_subject
    JSONModel(:subject).find(id).terms[0]["term"].should eq("1981 Heroes")
  end


  it "lets you list all subjects" do
    id = create_subject
    JSONModel(:subject).all(:page => 1)['results'].count.should eq(1)
  end


  it "knows its own URI" do
    id = create_subject
    JSONModel(:subject).find(id).uri.should eq("/subjects/#{id}")
  end


  it "lets you create a subject and update it" do
    id = create_subject
    subject = JSONModel(:subject).find(id)
    subject['ref_id'] = "CustomIdentifier123"
    subject.save

    JSONModel(:subject).find(id).ref_id.should eq("CustomIdentifier123")
  end
end
