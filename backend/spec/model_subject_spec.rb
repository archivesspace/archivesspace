require 'spec_helper'

describe 'Subject model' do

  it "Allows subjects to be created" do

    subject = Subject.create_from_json(JSONModel(:subject).
                                           from_hash({
                                                       "term" => "1981 Heroes",
                                                       "term_type" => "Cultural context"
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
                                               "term_type" => "Cultural context"
                                             }))
      end
    }.should raise_error(Sequel::DatabaseError)
  end

end
