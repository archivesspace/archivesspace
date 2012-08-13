require 'spec_helper'

describe 'Vocabulary model' do

  it "Allows vocabularies to be created" do

    vocabulary = Vocabulary.create_from_json(JSONModel(:vocabulary).
                                           from_hash({
                                                       "name" => "ABC",
                                                     }))

    Vocabulary[vocabulary[:id]].name.should eq("ABC")
  end


  it "Enforces name uniqueness" do
    lambda {
      2.times do
        Vocabulary.create_from_json(JSONModel(:vocabulary).
                                   from_hash({
                                               "name" => "ABC"
                                             }))
      end
    }.should raise_error(Sequel::DatabaseError)
  end

end
