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


  it "lets you list all accessions" do
    id = create_accession
    JSONModel(:accession).all.count.should eq(1)
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


  it "fails on missing properties" do
    JSONModel::strict_mode(false)

    expect { JSONModel(:accession).from_hash("id_0" => "abcdef") }.to raise_error(JSONModel::ValidationException)

    begin
      acc = JSONModel(:accession).from_hash("id_0" => "abcdef")
    rescue JSONModel::ValidationException => e
      errors = ["title", "accession_date"]
      warnings = ["content_description", "condition_description"]

      (e.errors.keys - errors).should eq([])
      (e.warnings.keys - warnings).should eq([])
    end

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


  it "won't let you overwrite the current version of a record with a stale copy" do

    created = create_accession

    acc1 = JSONModel(:accession).find(created)
    acc2 = JSONModel(:accession).find(created)

    acc1.id_1 = "5678"
    acc1.save

    # Working off the stale copy
    acc2.id_1 = "9999"
    expect {
      acc2.save
    }.to raise_error(ConflictException)

  end


  it "creates an accession with a rights statement" do
    acc = JSONModel(:accession).from_hash("id_0" => "1234",
                                          "title" => "The accession title",
                                          "content_description" => "The accession description",
                                          "condition_description" => "The condition description",
                                          "accession_date" => "2012-05-03",
                                          "rights_statements" => [
                                            {
                                              "identifier" => "abc123",
                                              "rights_type" => "intellectual_property",
                                              "ip_status" => "copyrighted",
                                              "jurisdiction" => "AU",
                                            }
                                          ]).save
    JSONModel(:accession).find(acc).rights_statements.length.should eq(1)
    JSONModel(:accession).find(acc).rights_statements[0]["identifier"].should eq("abc123")
    JSONModel(:accession).find(acc).rights_statements[0]["active"].should eq(true)
  end


  it "creates an accession with a deaccession" do
    acc = JSONModel(:accession).from_hash("id_0" => "1234",
                                          "title" => "The accession title",
                                          "content_description" => "The accession description",
                                          "condition_description" => "The condition description",
                                          "accession_date" => "2012-05-03",
                                          "deaccessions" => [
                                            {
                                              "whole_part" => false,
                                              "description" => "A description of this deaccession",
                                              "date" => {
                                                            "date_type" => "single",
                                                            "label" => "deaccession",
                                                            "begin" => "2012-05-14",
                                                          },
                                            }
                                          ]).save
    JSONModel(:accession).find(acc).deaccessions.length.should eq(1)
    JSONModel(:accession).find(acc).deaccessions[0]["whole_part"].should eq(false)
    JSONModel(:accession).find(acc).deaccessions[0]["date"]["begin"].should eq("2012-05-14")
  end


end
