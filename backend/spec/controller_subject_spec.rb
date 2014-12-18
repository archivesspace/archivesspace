require 'spec_helper'

describe 'Subject controller' do

  before(:each) do
    vocab = JSONModel(:vocabulary).from_hash("name" => "Cool Vocab",
                                             "ref_id" => "coolid"
                                             )
    vocab.save
    @vocab_id = vocab.id
  end


  it "lets you create a subject and get it back" do
    subject = create(:json_subject, :terms => [build(:json_term, "term" => "1981 Heroes")], :scope_note => "scopenote")
    JSONModel(:subject).find(subject.id).terms[0]["term"].should eq("1981 Heroes")
    JSONModel(:subject).find(subject.id).scope_note.should eq("scopenote")
  end


  it "lets you list all subjects" do
    create(:json_subject)
    JSONModel(:subject).all(:page => 1)['results'].count.should be > 0
  end


  it "knows its own URI" do
    id = create(:json_subject).id
    JSONModel(:subject).find(id).uri.should eq("/subjects/#{id}")
  end


  it "lets you create a subject and update it" do
    subject = create(:json_subject)
    subject['authority_id'] = "CustomIdentifier123"
    subject.save

    JSONModel(:subject).find(subject.id).authority_id.should eq("CustomIdentifier123")
  end


  it "can resolve an id from a subject uri" do
    id = create(:json_subject).id
    subject = JSONModel(:subject).find(id)

    JSONModel(:subject).id_for(subject['uri']).should eq(id)
  end

end
