require 'spec_helper'

describe 'Term model' do

  before(:each) do
    vocab = JSONModel(:vocabulary).from_hash("name" => "Cool Vocab",
                                             "ref_id" => "cool"
                                             )
    vocab.save
    @vocab_id = vocab.id
  end


  it "Allows a term to be created" do

    term = Term.create_from_json(JSONModel(:term).
                                 from_hash({
                                             "term" => "a test term",
                                             "term_type" => "cultural_context",
                                             "vocabulary" => JSONModel(:vocabulary).uri_for(@vocab_id)
                                           }))

    expect(Term[term[:id]].term).to eq("a test term")
    expect(Term[term[:id]].term_type).to eq("cultural_context")
  end


  it "Enforces term uniqueness" do
    expect(lambda {
      2.times do
        Term.create_from_json(JSONModel(:term).
                              from_hash({
                                          "term" => "a test term",
                                          "term_type" => "cultural_context",
                                          "vocabulary" => JSONModel(:vocabulary).uri_for(@vocab_id)
                                        }))
      end
    }).to raise_error(Sequel::ValidationFailed)
  end

end
