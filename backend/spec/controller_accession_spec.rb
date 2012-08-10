require 'spec_helper'

describe 'Accession controller' do

  before(:each) do
    make_test_repo
  end


  def create_accession
    JSONModel(:accession).from_hash("id_0" => "1234",
                                    "title" => "The accession title",
                                    "content_description" => "The accession description",
                                    "condition_description" => "The condition description",
                                    "accession_date" => "2012-05-03").save
  end


  it "lets you create an accession and get it back" do
    id = create_accession
    JSONModel(:accession).find(id).title.should eq("The accession title")
  end


  it "fails when you try to update an accession that doesn't exist" do
    acc = JSONModel(:accession).from_hash("id_0" => "1234",
                                          "title" => "The accession title",
                                          "content_description" => "The accession description",
                                          "condition_description" => "The condition description",
                                          "accession_date" => "2012-05-03")
    acc.uri = "#{@repo}/accessions/9999"

    expect { acc.save }.to raise_error
  end


  it "warns about missing properties" do
    JSONModel::strict_mode(false)
    acc = JSONModel(:accession).from_hash("id_0" => "abcdef")
    acc.save

    known_warnings = ["accession_date", "condition_description", "content_description", "title"]
    (known_warnings - acc._exceptions[:warnings].keys).should eq([])
    JSONModel::strict_mode(true)
  end


  it "supports updates" do
    created = create_accession

    acc = JSONModel(:accession).find(created)
    acc.id_1 = "5678"
    acc.save

    JSONModel(:accession).find(created).id_1.should eq("5678")
  end


  it "knows its own URI" do
    created = create_accession
    JSONModel(:accession).find(created).uri.should eq("#{@repo}/accessions/#{created}")
  end

end
