require_relative 'spec_helper'

describe 'Accession model' do

  it "allows accessions to be created" do
    accession = create_accession

    expect(Accession[accession[:id]].title).to eq("Papers of Mark Triggs")
  end


  it "enforces ID uniqueness" do
    expect(lambda {
      2.times do
        Accession.create_from_json(build(:json_accession,
                                         {:id_0 => "1234",
                                          :id_1 => "5678",
                                          :id_2 => "9876",
                                          :id_3 => "5432"
                                          }),
                                   :repo_id => $repo_id)
      end
    }).to raise_error(Sequel::ValidationFailed)
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
    }.to raise_error(JSONModel::ValidationException)
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
    }.not_to raise_error
  end


  it "enforces ID max length" do
    expect(lambda {
      2.times do
        Accession.create_from_json(build(:json_accession,
                                         {
                                           :id_0 => "x" * 51
                                         }),
                                   :repo_id => $repo_id)
      end
    }).to raise_error(Sequel::ValidationFailed)
  end


  it "allows long condition descriptions" do
    long_string = "x" * 1024

    accession = Accession.create_from_json(build(:json_accession,
                                                 :condition_description => long_string
                                                 ),
                                          :repo_id => $repo_id)

    expect(Accession[accession[:id]].condition_description).to eq(long_string)
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


    expect(Accession[accession[:id]].date.length).to eq(1)
    expect(Accession[accession[:id]].date[0].begin).to eq("2012-05-14")
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


    expect(Accession[accession[:id]].external_document.length).to eq(1)
    expect(Accession[accession[:id]].external_document[0].title).to eq("My external document")
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
                                            "title" => "My external document",
                                            "location" => "http://www.foobar.com",
                                          },
                                        ]
                                       ),
                                :repo_id => $repo_id)

    }.to raise_error(Sequel::ValidationFailed)
  end

  it "allows an accession created with external documents with same title duplicate locations" do

     accession =  Accession.create_from_json(build(:json_accession,
                                       :external_documents => [
                                          {
                                            "title" => "My external document",
                                            "location" => "http://www.foobar.com",
                                          },
                                          {
                                            "title" => "My duplicate external document",
                                            "location" => "http://www.foobar.com",
                                          },
                                        ]
                                       ),
                                :repo_id => $repo_id)
       expect(Accession[accession[:id]].external_document.length).to eq(2)
  end


  it "allows accessions to be created with a rights statement" do

    accession = Accession.create_from_json(build(:json_accession,
                                                 :rights_statements => [
                                                    {
                                                      "identifier" => "abc123",
                                                      "rights_type" => "copyright",
                                                      "status" => "copyrighted",
                                                      "jurisdiction" => "AU",
                                                      "start_date" => '1999-01-01',
                                                    }
                                                  ]
                                                 ),
                                          :repo_id => $repo_id)

    expect(Accession[accession[:id]].rights_statement.length).to eq(1)
    expect(Accession[accession[:id]].rights_statement[0].identifier).to eq("abc123")
  end

  it "allows accessions to be created with a rights statement with an external document and identifier type" do
    accession = Accession.create_from_json(build(:json_accession,
                                                 :rights_statements => [
                                                   {
                                                     "identifier" => "abc123",
                                                     "rights_type" => "copyright",
                                                     "status" => "copyrighted",
                                                     "jurisdiction" => "AU",
                                                     "start_date" => '1999-01-01',
                                                     "external_documents" => [build(:json_rights_statement_external_document,
                                                                                    :identifier_type => 'trove')]
                                                   }
                                                 ]
                                           ),
                                           :repo_id => $repo_id)

    expect(Accession.to_jsonmodel(accession[:id]).rights_statements.length).to eq(1)
    expect(Accession.to_jsonmodel(accession[:id]).rights_statements.first['external_documents'].length).to eq(1)
    expect(Accession.to_jsonmodel(accession[:id]).rights_statements.first['external_documents'].first['identifier_type']).to eq('trove')
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


    expect(Accession[accession[:id]].deaccession.length).to eq(1)
    expect(Accession[accession[:id]].deaccession[0].scope).to eq("whole")
    expect(Accession[accession[:id]].deaccession[0].date.begin).to eq("2012-05-14")
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
    }.to raise_error(JSONModel::ValidationException)
  end

  it "allows accession's collection management record to have a processing status" do
    accession = Accession.create_from_json(build(:json_accession,
                                                 :collection_management =>
                                                 {
                                                    "processing_status" => "completed"
                                                 }
                                                 ),
                                           :repo_id => $repo_id)
    expect(Accession[accession[:id]].collection_management.processing_status).to eq("completed")
  end



  it "allows accessions to be created with user defined fields" do
    accession = Accession.create_from_json(build(:json_accession,
                                                 :user_defined =>
                                                    {
                                                      "integer_1" => "11",
                                                      "real_1" => "3.14159",
                                                    }
                                                 ),
                                          :repo_id => $repo_id)

    expect(Accession[accession[:id]].user_defined.integer_1).to eq("11")
    expect(Accession[accession[:id]].user_defined.real_1).to eq("3.14159")
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
    }.to raise_error(JSONModel::ValidationException)

    expect {
      accession = Accession.create_from_json(build(:json_accession,
                                                   :user_defined =>
                                                   {
                                                     "integer_2" => "moo",
                                                   }
                                                   ),
                                             :repo_id => $repo_id)
    }.to raise_error(JSONModel::ValidationException)

    expect {
      accession = Accession.create_from_json(build(:json_accession,
                                                   :user_defined =>
                                                   {
                                                     "real_1" => "3.1415926",
                                                   }
                                                   ),
                                             :repo_id => $repo_id)
    }.to raise_error(JSONModel::ValidationException)

    expect {
      accession = Accession.create_from_json(build(:json_accession,
                                                   :user_defined =>
                                                   {
                                                     "real_2" => "real_1 failed because you're only allowed five decimal places",
                                                   }
                                                   ),
                                             :repo_id => $repo_id)
    }.to raise_error(JSONModel::ValidationException)

  end


  it "can be linked to a classification" do
    classification = build(:json_classification,
                           :title => "top-level classification",
                           :identifier => "abcdef",
                           :description => "A classification")

    classification = Classification.create_from_json(classification)
    accession = create_accession(:classifications => [ {'ref' => classification.uri} ])

    expect(accession.related_records(:classification).first.title).to eq("top-level classification")
  end


  it "respects the publish preference when creating accessions" do
    accession = create_accession

    expect(Accession[accession[:id]].publish).to eq(Preference.defaults['publish'] ? 1 : 0)
  end


  it "can create an accession consisting of a number of parts" do
    parent = create_accession

    children = 3.times.map {
      rlshp = JSONModel(:accession_parts_relationship).from_hash('relator' => 'forms_part_of',
                                                                 'relator_type' => 'part',
                                                                 'ref' => parent.uri)
      create_accession('related_accessions' => [rlshp.to_hash])
    }

    # Relationship can be seen from the parent
    parts_parent = Accession.to_jsonmodel(parent.id)['related_accessions']

    expect(parts_parent.length).to eq(3)
    expect(parts_parent.map {|p| p['relator']}.uniq).to eq(['has_part'])
    expect(children.map(&:uri) - parts_parent.map {|p| p['ref']}).to eq([])

    # And from the children
    children.each do |child|
      parts_child = Accession.to_jsonmodel(child.id)['related_accessions']

      expect(parts_child.length).to eq(1)
      expect(parts_child.map {|p| p['relator']}.uniq).to eq(['forms_part_of'])
      expect(parts_child.first['ref']).to eq(parent.uri)
    end
  end


  it "can bind two accessions together in a sibling relationship" do
    ernie = create_accession

    rlshp = JSONModel(:accession_sibling_relationship).from_hash('relator' => 'sibling_of',
                                                                 'relator_type' => 'bound_with',
                                                                 'ref' => ernie.uri)

    bert = create_accession('related_accessions' => [rlshp.to_hash])

    expect(Accession.to_jsonmodel(ernie.id)['related_accessions'].first['ref']).to eq(bert.uri)
    expect(Accession.to_jsonmodel(bert.id)['related_accessions'].first['ref']).to eq(ernie.uri)
  end

end
