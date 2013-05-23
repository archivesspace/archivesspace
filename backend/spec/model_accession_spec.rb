require 'spec_helper'

def create_accession
  Accession.create_from_json(build(:json_accession,
                                   :title => "Papers of Mark Triggs"),
                             :repo_id => $repo_id)
end

describe 'Accession model' do

  it "allows accessions to be created" do
    accession = create_accession

    Accession[accession[:id]].title.should eq("Papers of Mark Triggs")
  end


  it "enforces ID uniqueness" do
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


  it "does not allow a gap in an id sequence" do
    expect {
      Accession.create_from_json(build(:json_accession,
                                       {:id_0 => "1234",
                                         :id_1 => "5678",
                                         :id_2 => "",
                                         :id_3 => "5432"
                                       }), 
                                 :repo_id => $repo_id)
    }.to raise_error(ValidationException)
  end


  it "doesn't enforce ID uniqueness between repositories" do
    repo1 = make_test_repo("REPO1")
    repo2 = make_test_repo("REPO2")

    expect {
      [repo1, repo2].each do |repo_id|
        Accession.create_from_json(build(:json_accession,
                                         {:id_0 => "1234",
                                          :id_1 => "5678",
                                          :id_2 => "9876",
                                          :id_3 => "5432"
                                          }),
                                   :repo_id => repo_id)
      end
    }.to_not raise_error
  end


  it "enforces ID max length" do
    lambda {
      2.times do
        Accession.create_from_json(build(:json_accession,
                                         {
                                           :id_0 => "x" * 51
                                         }),
                                   :repo_id => $repo_id)
      end
    }.should raise_error(Sequel::ValidationFailed)
  end


  it "allows long condition descriptions" do
    long_string = "x" * 1024
    
    accession = Accession.create_from_json(build(:json_accession,
                                                 :condition_description => long_string
                                                 ),
                                          :repo_id => $repo_id)

    Accession[accession[:id]].condition_description.should eq(long_string)
  end


  it "allows accessions to be created with a date" do
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


  it "allows accessions to be created with an external document" do
    
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


  it "allows accessions to be created with a rights statement" do
    
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


  it "allows accessions to be created with a deaccession" do
    
    accession = Accession.create_from_json(build(:json_accession,
                                                 :deaccessions => [
                                                    {
                                                      "scope" => "whole",
                                                      "description" => "A description of this deaccession",
                                                      "date" => build(:json_date,
                                                                      :begin => '2012-05-14'),
                                                    }
                                                  ]
                                                 ),
                                          :repo_id => $repo_id)


    Accession[accession[:id]].deaccession.length.should eq(1)
    Accession[accession[:id]].deaccession[0].scope.should eq("whole")
    Accession[accession[:id]].deaccession[0].date.begin.should eq("2012-05-14")
  end


  it "can suppress an accession record" do
    accession = create_accession
    accession.set_suppressed(true)

    create(:user, :username => 'nobody')

    as_test_user('nobody') do
      Accession.this_repo[accession.id].should eq(nil)
    end
  end


  it "allows accessions to be created with a collection management record" do
    accession = Accession.create_from_json(build(:json_accession,
                                                 :collection_management =>
                                                    {
                                                      "cataloged_note" => "just a note",
                                                    }
                                                 ),
                                          :repo_id => $repo_id)

    Accession[accession[:id]].collection_management.cataloged_note.should eq("just a note")
  end


  it "reports an error if the accession's collection management record has a total extent that lacks a type" do
    expect {
      accession = Accession.create_from_json(build(:json_accession,
                                                   :collection_management =>
                                                   {
                                                     "cataloging_note" => "just a note",
                                                     "processing_total_extent" => "11",
                                                   }
                                                   ),
                                             :repo_id => $repo_id)
    }.to raise_error(ValidationException)
  end


  it "allows accessions to be created with user defined fields" do
    accession = Accession.create_from_json(build(:json_accession,
                                                 :user_defined =>
                                                    {
                                                      "integer_1" => "11",
                                                    }
                                                 ),
                                          :repo_id => $repo_id)

    Accession[accession[:id]].user_defined.integer_1.should eq("11")
  end


  it "reports errors if the accession's user defined fields don't validate" do
    expect {
      accession = Accession.create_from_json(build(:json_accession,
                                                   :user_defined =>
                                                   {
                                                     "integer_1" => "3.1415",
                                                   }
                                                   ),
                                             :repo_id => $repo_id)
    }.to raise_error(ValidationException)

    expect {
      accession = Accession.create_from_json(build(:json_accession,
                                                   :user_defined =>
                                                   {
                                                     "integer_2" => "moo",
                                                   }
                                                   ),
                                             :repo_id => $repo_id)
    }.to raise_error(ValidationException)

    expect {
      accession = Accession.create_from_json(build(:json_accession,
                                                   :user_defined =>
                                                   {
                                                     "real_1" => "3.1415926",
                                                   }
                                                   ),
                                             :repo_id => $repo_id)
    }.to raise_error(ValidationException)

    expect {
      accession = Accession.create_from_json(build(:json_accession,
                                                   :user_defined =>
                                                   {
                                                     "real_2" => "real_1 failed because you're only allowed two decimal places",
                                                   }
                                                   ),
                                             :repo_id => $repo_id)
    }.to raise_error(ValidationException)

  end

end
