require 'spec_helper'

describe 'Rights Statement model' do

  def create_rights_statement(opts = {})
    RightsStatement.create_from_json(build(:json_rights_statement, opts), :repo_id => $repo_id)
  end


  it "Supports creating a new rights statement" do
    
    opts = {:identifier => generate(:alphanumstr)}
    
    rights_statement = create_rights_statement(opts)

    RightsStatement[rights_statement[:id]].identifier.should eq(opts[:identifier])
  end


  it "Does not Enforce identifier uniqueness within a single repository" do
    repo_one = create(:repo)
    repo_two = create(:repo)
    
    opts = {:identifier => generate(:alphanumstr)}

    expect {
      RightsStatement.create_from_json(build(:json_rights_statement, opts), :repo_id => repo_one.id)
      RightsStatement.create_from_json(build(:json_rights_statement, opts), :repo_id => repo_one.id)

    }.to_not raise_error

    # No problems here
    expect {
      RightsStatement.create_from_json(build(:json_rights_statement, opts), :repo_id => repo_two.id)
    }.to_not raise_error
  end


  it "Enforces validation rules when rights_type is copyright" do
    
    opts = {:rights_type => 'copyright'}
    
    expect { create_rights_statement(opts.merge(:status => nil)) }.to raise_error(JSONModel::ValidationException)
    expect { create_rights_statement(opts.merge(:jurisdiction => nil)) }.to raise_error(JSONModel::ValidationException)
    expect { create_rights_statement(opts.merge(:start_date => nil)) }.to raise_error(JSONModel::ValidationException)
    expect { create_rights_statement(opts) }.to_not raise_error
  end


  it "Enforces validation rules when rights_type is statute" do
    
    opts = {:rights_type => 'statute', 
            :status => nil,
            :statute_citation => generate(:alphanumstr)
            }
            
    expect { create_rights_statement(opts.merge(:jurisdiction => nil)) }.to raise_error(JSONModel::ValidationException)
    expect { create_rights_statement(opts.merge(:statute_citation => nil)) }.to raise_error(JSONModel::ValidationException)
    expect { create_rights_statement(opts.merge(:start_date => nil)) }.to raise_error(JSONModel::ValidationException)
    expect { create_rights_statement(opts) }.to_not raise_error
  end


  it "Enforces validation rules when rights_type is license" do
    
    opts = {:rights_type => 'license', 
            :status => nil, 
            :jurisdiction => nil,
            :license_terms => generate(:alphanumstr)
            }
            
    expect { create_rights_statement(opts.merge(:license_terms => nil)) }.to raise_error(JSONModel::ValidationException)
    expect { create_rights_statement(opts.merge(:start_date => nil)) }.to raise_error(JSONModel::ValidationException)
    expect { create_rights_statement(opts) }.to_not raise_error
  end

  it "Enforces validation rules when rights_type is other" do

    opts = {:rights_type => 'other',
            :status => nil,
            :jurisdiction => nil,
            :other_rights_basis => generate(:other_rights_basis)
    }

    expect { create_rights_statement(opts.merge(:other_rights_basis => nil)) }.to raise_error(JSONModel::ValidationException)
    expect { create_rights_statement(opts.merge(:start_date => nil)) }.to raise_error(JSONModel::ValidationException)
    expect { create_rights_statement(opts) }.to_not raise_error
  end

  it "Allows a rights statement to be created with an external document" do
    opts = {'external_documents' => [build(:json_rights_statement_external_document,
                                           :identifier_type => 'trove')]}
    
    rights_statement = create_rights_statement(opts)

    RightsStatement[rights_statement[:id]].external_document.length.should eq(1)
    RightsStatement[rights_statement[:id]].external_document[0].title.should eq(opts['external_documents'][0]['title'])
    RightsStatement.to_jsonmodel(rights_statement[:id]).external_documents[0]['identifier_type'] == 'trove'
  end

  it "requires an identifier type for any external document" do
    opts = {'external_documents' => [build(:json_rights_statement_external_document, {:identifier_type => nil})]}

    expect { create_rights_statement(opts) }.to raise_error(JSONModel::ValidationException)
  end

  it "Allows a rights statement to be created with a linked agent" do

    agent = create(:json_agent_person)
    opts = {'linked_agents' => [{'ref' => agent.uri}]}

    rights_statement = create_rights_statement(opts)

    RightsStatement.to_jsonmodel(rights_statement[:id]).linked_agents.length.should eq(1)
    RightsStatement.to_jsonmodel(rights_statement[:id]).linked_agents[0]['ref'].should eq(agent.uri)
  end

  it "Allows a rights statement to be created with a note" do
    opts = {
      'notes' => [build(:json_note_rights_statement)]
    }

    rights_statement = create_rights_statement(opts)

    RightsStatement.to_jsonmodel(rights_statement[:id]).notes.length.should eq(1)
  end

  it "Allows a rights statement to be created with an act" do
    opts = {
      :acts => [build(:json_rights_statement_act)]
    }

    rights_statement = create_rights_statement(opts)

    RightsStatement.to_jsonmodel(rights_statement[:id]).acts.length.should eq(1)
  end

  it "applies validation rules to act" do
    expect { create_rights_statement({
                                       'acts' => [build(:json_rights_statement_act, :act_type => nil)]
                                     }) }.to raise_error(JSONModel::ValidationException)

    expect { create_rights_statement({
                                       'acts' => [build(:json_rights_statement_act, :restriction => nil)]
                                     }) }.to raise_error(JSONModel::ValidationException)

    expect { create_rights_statement({
                                       'acts' => [build(:json_rights_statement_act, :start_date => nil)]
                                     }) }.to raise_error(JSONModel::ValidationException)

    expect { create_rights_statement({
                                       'acts' => [build(:json_rights_statement_act)]
                                     }) }.to_not raise_error
  end

  it "will generate a ref_id if non is provided" do
    rights_statement = create_rights_statement(:identifier => nil)

    RightsStatement[rights_statement[:id]].identifier.should_not be_nil
  end

end
