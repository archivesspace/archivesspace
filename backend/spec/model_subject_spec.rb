require 'spec_helper'

describe 'Subject model' do

  def createTerm
    @count += 1
    Term.create_from_json(JSONModel(:term).
                          from_hash({
                                      "term" => "test#{Time.now.to_i}_#{@count}",
                                      "term_type" => "cultural_context",
                                      "vocabulary" => JSONModel(:vocabulary).uri_for(@vocab_id)
                                    }))
  end


  before(:all) do
    @count = 0
  end

  before(:each) do
    vocab = JSONModel(:vocabulary).from_hash("name" => "Cool Vocab",
                                             "ref_id" => "cool"
                                             )
    vocab.save
    @vocab_id = vocab.id
  end


  it "Allows a basic subject to be created" do
    term_id = createTerm.id
    subject = Subject.create_from_json(JSONModel(:subject).
                                       from_hash({
                                                   "terms" => [
                                                               JSONModel(:term).uri_for(term_id)
                                                              ],
                                                   "vocabulary" => JSONModel(:vocabulary).uri_for(@vocab_id)
                                                 }))

    Subject[subject[:id]].term[0].id.should eq(term_id)
  end


  it "Allows a subject with multiple terms to be created" do
    term_id_0 = createTerm.id
    term_id_1 = createTerm.id
    term_id_2 = createTerm.id
    term_id_3 = createTerm.id
    subject = Subject.create_from_json(JSONModel(:subject).
                                       from_hash({
                                                   "terms" => [
                                                               JSONModel(:term).uri_for(term_id_0),
                                                               JSONModel(:term).uri_for(term_id_1),
                                                               JSONModel(:term).uri_for(term_id_2),
                                                               JSONModel(:term).uri_for(term_id_3),
                                                              ],
                                                   "vocabulary" => JSONModel(:vocabulary).uri_for(@vocab_id)
                                                 }))

    Subject[subject[:id]].term[0].id.should eq(term_id_0)
    Subject[subject[:id]].term[1].id.should eq(term_id_1)
    Subject[subject[:id]].term[2].id.should eq(term_id_2)
    Subject[subject[:id]].term[3].id.should eq(term_id_3)
  end


  it "ensures unique subjects may only be created" do
    term_id_0 = createTerm.id
    term_id_1 = createTerm.id
    subject_a = Subject.create_from_json(JSONModel(:subject).
                                         from_hash({
                                                     "terms" => [
                                                       JSONModel(:term).uri_for(term_id_0),
                                                       JSONModel(:term).uri_for(term_id_1),
                                                     ],
                                                     "vocabulary" => JSONModel(:vocabulary).uri_for(@vocab_id)
                                                   }))
    expect {
      subject_b = Subject.create_from_json(JSONModel(:subject).
                                           from_hash({
                                                       "terms" => [
                                                         JSONModel(:term).uri_for(term_id_0),
                                                         JSONModel(:term).uri_for(term_id_1),
                                                       ],
                                                       "vocabulary" => JSONModel(:vocabulary).uri_for(@vocab_id)
                                                     }))
     }.to raise_error(Sequel::ValidationFailed)
  end
  
  it "ensures subject heading identifiers are unique within a vocab" do
    vocab = create(:json_vocab)
    
    heading_id = 1 == rand(2) ? "http://example.com/example" : "12aBCD12"
    
    subject_a = create(:json_subject, {:vocabulary => vocab.uri, :ref_id => heading_id})
   
   expect {
      create(:json_subject, {:vocabulary => vocab.uri})
    }.to_not raise_error(JSONModel::ValidationException)
    
    expect {
      create(:json_subject, {:vocabulary => vocab.uri, :ref_id => heading_id})
    }.to raise_error(JSONModel::ValidationException)
    
    
  end


  it "generates a subject title" do
    term_id_0 = createTerm
    term_id_1 = createTerm

    subject = Subject.create_from_json(JSONModel(:subject).
                                         from_hash({
                                                     "terms" => [
                                                       JSONModel(:term).uri_for(term_id_0.id),
                                                       JSONModel(:term).uri_for(term_id_1.id)
                                                     ],
                                                     "vocabulary" => JSONModel(:vocabulary).uri_for(@vocab_id)
                                                   }))

    #term_id_2 = createTerm

    Subject[subject[:id]].title.should eq("#{term_id_0.term} -- #{term_id_1.term}")
  end


end
