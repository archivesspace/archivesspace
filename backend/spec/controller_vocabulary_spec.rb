require 'spec_helper'

describe 'Vocabulary controller' do

  def create_vocabulary
    vocabulary = JSONModel(:vocabulary).from_hash("name" => "ABC")

    vocabulary.save
  end


  it "lets you create a vocabulary and get it back" do
    id = create_vocabulary
    JSONModel(:vocabulary).find(id).name.should eq("ABC")
  end


  it "fails when you try to update a vocabulary that doesn't exist" do
    vocabulary = JSONModel(:vocabulary).from_hash("name" => "ABC")

    vocabulary.uri = "/vocabularies/999999"

    expect { vocabulary.save }.to raise_error
  end


  it "supports updates" do
    id = create_vocabulary

    vocabulary = JSONModel(:vocabulary).find(id)
    vocabulary.name = "XYZ"
    vocabulary.save

    JSONModel(:vocabulary).find(id).name.should eq("XYZ")
  end


  it "knows its own URI" do
    id = create_vocabulary

    JSONModel(:vocabulary).find(id).uri.should eq("/vocabularies/#{id}")
  end

end
