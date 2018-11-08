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
    expect(JSONModel(:subject).find(subject.id).terms[0]["term"]).to eq("1981 Heroes")
    expect(JSONModel(:subject).find(subject.id).scope_note).to eq("scopenote")
  end


  it "lets you list all subjects" do
    create(:json_subject)
    expect(JSONModel(:subject).all(:page => 1)['results'].count).to be > 0
  end


  it "knows its own URI" do
    id = create(:json_subject).id
    expect(JSONModel(:subject).find(id).uri).to eq("/subjects/#{id}")
  end


  it "lets you create a subject and update it" do
    subject = create(:json_subject)
    subject['authority_id'] = "CustomIdentifier123"
    subject.save

    expect(JSONModel(:subject).find(subject.id).authority_id).to eq("CustomIdentifier123")
  end


  it "can resolve an id from a subject uri" do
    id = create(:json_subject).id
    subject = JSONModel(:subject).find(id)

    expect(JSONModel(:subject).id_for(subject['uri'])).to eq(id)
  end

end
