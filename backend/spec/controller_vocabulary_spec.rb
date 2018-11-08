require 'spec_helper'

describe 'Vocabulary controller' do

  def create_vocabulary
    vocabulary = JSONModel(:vocabulary).from_hash("name" => "ABC",
                                                  "ref_id" => "abc"
                                                  )

    vocabulary.save
  end


  it "lets you create a vocabulary and get it back" do
    id = create_vocabulary
    expect(JSONModel(:vocabulary).find(id).name).to eq("ABC")
  end


  it "lets you list all vocabularies" do
    vocab_count = JSONModel(:vocabulary).all.count
    create_vocabulary
    expect(JSONModel(:vocabulary).all.count).to eq(vocab_count + 1)
  end


  it "fails when you try to update a vocabulary that doesn't exist" do
    vocabulary = JSONModel(:vocabulary).from_hash("name" => "ABC",
                                                  "ref_id" => "abc"
                                                  )

    vocabulary.uri = "/vocabularies/999999"

    expect { vocabulary.save }.to raise_error(RecordNotFound)
  end


  it "supports updates" do
    id = create_vocabulary

    vocabulary = JSONModel(:vocabulary).find(id)
    vocabulary.name = "XYZ"
    vocabulary.save

    expect(JSONModel(:vocabulary).find(id).name).to eq("XYZ")
  end


  it "knows its own URI" do
    id = create_vocabulary

    expect(JSONModel(:vocabulary).find(id).uri).to eq("/vocabularies/#{id}")
  end

  it "can return a vocabulary record based on a ref_id" do
    v1 = JSONModel(:vocabulary).from_hash("name" => "ABC",
                                          "ref_id" => "abc"
                                          )

    v1.save

    v2 = JSONModel(:vocabulary).from_hash("name" => "XYZ",
                                          "ref_id" => "xyz"
                                          )
    v2.save

    set = JSONModel(:vocabulary).all({:ref_id => "xyz"})
    expect(set.count).to eq(1)
  end


  it "lets you list all terms" do
    id = create_vocabulary
    vocab_uri = JSONModel(:vocabulary).uri_for(id)

    subject = JSONModel(:subject).from_hash(
                                            "source" => "local",
                                            "terms" => [{
                                                          "term" => "1981 Heroes",
                                                          "term_type" => "cultural_context",
                                                          "vocabulary" => vocab_uri
                                                        }],
                                            "vocabulary" => vocab_uri)

    subject.save

    response = get "#{vocab_uri}/terms"
    expect(JSON(response.body).length).to eq(1)
  end

end
