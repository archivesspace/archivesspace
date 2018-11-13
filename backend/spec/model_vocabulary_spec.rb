require 'spec_helper'

describe 'Vocabulary model' do

  it "Allows vocabularies to be created" do

    vocabulary = Vocabulary.create_from_json(JSONModel(:vocabulary).
                                             from_hash({
                                                         "name" => "ABC",
                                                         "ref_id" => "123"
                                                       }))

    expect(Vocabulary[vocabulary[:id]].name).to eq("ABC")
  end


  it "Enforces name uniqueness" do
    expect(lambda {
      2.times do
        Vocabulary.create_from_json(JSONModel(:vocabulary).
                                    from_hash({
                                                "name" => "ABC",
                                                "ref_id" => "#{(0...4).map{ ('a'..'z').to_a[rand(26)] }.join}"
                                              }))
      end
    }).to raise_error(Sequel::DatabaseError)
  end

  it "Enforces ref_id uniqueness" do
    expect(lambda {
      2.times do
        Vocabulary.create_from_json(JSONModel(:vocabulary).
                                    from_hash({
                                                "name" => "#{(0...8).map{ ('a'..'z').to_a[rand(26)] }.join}",
                                                "ref_id" => "aabb"
                                              }))
      end
    }).to raise_error(Sequel::DatabaseError)
  end

  it "Can lookup a vocabulary by refid" do
    Vocabulary.create_from_json(JSONModel(:vocabulary).
                                from_hash({
                                            "name" => "Bill and Ted's Excellent Ontology",
                                            "ref_id" => "excellent"
                                          }))
    Vocabulary.create_from_json(JSONModel(:vocabulary).
                                from_hash({
                                            "name" => "Wayne's Taxonomy",
                                            "ref_id" => "schwing"
                                          }))
    vocab = Vocabulary.set({:ref_id => "schwing"})
    expect(vocab.count).to eq 1
    expect(vocab.first.name).to eq("Wayne's Taxonomy")

  end

end
