require 'spec_helper'

describe 'Subject model' do

  def createTerm
    @count += 1
    Term.create_from_json(JSONModel(:term).
                          from_hash({
                                      "term" => "test#{Time.now.to_i}_#{@count}",
                                      "term_type" => "Cultural context",
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

end
