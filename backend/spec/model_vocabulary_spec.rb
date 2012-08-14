require 'spec_helper'

describe 'Vocabulary model' do

  it "Allows vocabularies to be created" do

    vocabulary = Vocabulary.create_from_json(JSONModel(:vocabulary).
                                           from_hash({
                                                       "name" => "ABC",
                                                       "ref_id" => "123"
                                                     }))

    Vocabulary[vocabulary[:id]].name.should eq("ABC")
  end


  it "Enforces name uniqueness" do
    lambda {
      2.times do
        Vocabulary.create_from_json(JSONModel(:vocabulary).
                                   from_hash({
                                               "name" => "ABC",
                                               "ref_id" => "#{(0...4).map{ ('a'..'z').to_a[rand(26)] }.join}"
                                             }))
      end
    }.should raise_error(Sequel::DatabaseError)
  end
  
  it "Enforces ref_id uniqueness" do
    lambda {
      2.times do
        Vocabulary.create_from_json(JSONModel(:vocabulary).
                                   from_hash({
                                               "name" => "#{(0...8).map{ ('a'..'z').to_a[rand(26)] }.join}",
                                               "ref_id" => "aabb"
                                             }))
      end
    }.should raise_error(Sequel::DatabaseError)
  end

end
