require 'spec_helper'

describe 'Subject model' do
  
  before(:each) do
    vocab = JSONModel(:vocabulary).from_hash("name" => "Cool Vocab")
    vocab.save
    @vocab_id = vocab.id
  end
  
  
  it "Allows subjects to be created" do

    subject = Subject.create_from_json(JSONModel(:subject).
                                           from_hash({
                                                       "term" => "1981 Heroes",
                                                       "term_type" => "Cultural context",
                                                       "vocabulary" => JSONModel(:vocabulary).uri_for(@vocab_id)
                                                     }))

    Subject[subject[:id]].term.should eq("1981 Heroes")
    Subject[subject[:id]].term_type.should eq("Cultural context")
  end


  it "Enforces term uniqueness" do
    lambda {
      2.times do
        Subject.create_from_json(JSONModel(:subject).
                                   from_hash({
                                               "term" => "1981 Heroes",
                                               "term_type" => "Cultural context",
                                               "vocabulary" => JSONModel(:vocabulary).uri_for(@vocab_id)
                                             }))
      end
    }.should raise_error
  end

end
