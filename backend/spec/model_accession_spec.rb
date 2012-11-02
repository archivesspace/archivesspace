require 'spec_helper'

describe 'Accession model' do

  it "Allows accessions to be created" do
    accession = Accession.create_from_json(build(:json_accession,
                                                 :title => "Papers of Mark Triggs"
                                                 ), 
                                           :repo_id => $repo_id)

    Accession[accession[:id]].title.should eq("Papers of Mark Triggs")
  end


  it "Enforces ID uniqueness" do
    lambda {
      2.times do
        Accession.create_from_json(build(:json_accession,
                                         {:id_0 => "1234",
                                          :id_1 => "5678",
                                          :id_2 => "9876",
                                          :id_3 => "5432"
                                          }), 
                                   :repo_id => $repo_id)
      end
    }.should raise_error(Sequel::ValidationFailed)
  end


  it "Allows long condition descriptions" do
    long_string = "x" * 1024
    
    accession = Accession.create_from_json(build(:json_accession,
                                                 :condition_description => long_string
                                                 ),
                                          :repo_id => $repo_id)

    Accession[accession[:id]].condition_description.should eq(long_string)
  end


  it "Allows accessions to be created with a date" do
    accession = Accession.create_from_json(build(:json_accession,
                                                 :dates => [
                                                   {
                                                     "date_type" => "single",
                                                     "label" => "creation",
                                                     "begin" => "2012-05-14",
                                                     "end" => "2012-05-14",
                                                    }
                                                  ]
                                                 ),
                                          :repo_id => $repo_id)
    

    Accession[accession[:id]].date.length.should eq(1)
    Accession[accession[:id]].date[0].begin.should eq("2012-05-14")
  end


  it "Allows accessions to be created with an external document" do
    
    accession = Accession.create_from_json(build(:json_accession,
                                                 :external_documents => [
                                                    {
                                                      "title" => "My external document",
                                                      "location" => "http://www.foobar.com",
                                                    }
                                                  ]
                                                 ),
                                          :repo_id => $repo_id)


    Accession[accession[:id]].external_document.length.should eq(1)
    Accession[accession[:id]].external_document[0].title.should eq("My external document")
  end


  it "throws an error when accession created with duplicate external documents" do
    expect {
      
      Accession.create_from_json(build(:json_accession,
                                       :external_documents => [
                                          {
                                            "title" => "My external document",
                                            "location" => "http://www.foobar.com",
                                          },
                                          {
                                            "title" => "My other document",
                                            "location" => "http://www.foobar.com",
                                          },
                                        ]
                                       ),
                                :repo_id => $repo_id)

    }.to raise_error(Sequel::ValidationFailed)
  end


  it "Allows accessions to be created with a rights statement" do
    
    accession = Accession.create_from_json(build(:json_accession,
                                                 :rights_statements => [
                                                    {
                                                      "identifier" => "abc123",
                                                      "rights_type" => "intellectual_property",
                                                      "ip_status" => "copyrighted",
                                                      "jurisdiction" => "AU",
                                                    }
                                                  ]
                                                 ),
                                          :repo_id => $repo_id)

    Accession[accession[:id]].rights_statement.length.should eq(1)
    Accession[accession[:id]].rights_statement[0].identifier.should eq("abc123")
  end


  it "Allows accessions to be created with a deaccession" do
    
    accession = Accession.create_from_json(build(:json_accession,
                                                 :deaccessions => [
                                                    {
                                                      "whole_part" => false,
                                                      "description" => "A description of this deaccession",
                                                      "date" => build(:json_date,
                                                                      :begin => '2012-05-14').to_hash,
                                                    }
                                                  ]
                                                 ),
                                          :repo_id => $repo_id)


    Accession[accession[:id]].deaccession.length.should eq(1)
    Accession[accession[:id]].deaccession[0].whole_part.should eq(0)
    Accession[accession[:id]].deaccession[0].date.begin.should eq("2012-05-14")
  end


end
