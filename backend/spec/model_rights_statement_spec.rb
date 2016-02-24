require 'spec_helper'

describe 'Rights Statement model' do

  def create_rights_statement(opts = {})
    RightsStatement.create_from_json(build(:json_rights_statement, opts), :repo_id => $repo_id)
  end


  it "Supports creating a new rights statement" do
    
    opts = {:identifier => generate(:alphanumstr), :active => true}
    
    rights_statement = create_rights_statement(opts)

    RightsStatement[rights_statement[:id]].identifier.should eq(opts[:identifier])
    RightsStatement[rights_statement[:id]].active.should eq(1)
  end


  it "creating a new rights statement and with active set to false" do
    
    opts = {:identifier => generate(:alphanumstr), :active => false}
    
    rights_statement = create_rights_statement(opts)

    RightsStatement[rights_statement[:id]].identifier.should eq(opts[:identifier])
    RightsStatement[rights_statement[:id]].active.should eq(0)
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


  it "Enforces validation rules when rights_type is intellectual_property" do
    
    opts = {:rights_type => 'intellectual_property', :ip_status => nil, :jurisdiction => nil}
    
    expect { create_rights_statement(opts) }.to raise_error(JSONModel::ValidationException)

    opts.delete(:ip_status)

    expect { create_rights_statement(opts) }.to raise_error(JSONModel::ValidationException)

    opts.delete(:jurisdiction)

    # this is ok though
    expect { create_rights_statement(opts) }.to_not raise_error
  end


  it "Enforces validation rules when rights_type is statute" do
    
    opts = {:rights_type => 'statute', 
            :ip_status => nil, 
            :jurisdiction => nil,
            :statute_citation => generate(:alphanumstr)
            }
            
    expect { create_rights_statement(opts) }.to raise_error(JSONModel::ValidationException)

    opts.delete(:statute_citation)
    opts[:jurisdiction] = generate(:jurisdiction)

    expect { create_rights_statement(opts) }.to raise_error(JSONModel::ValidationException)

    opts[:statute_citation] = generate(:alphanumstr)
    
    expect { create_rights_statement(opts) }.to_not raise_error
  end


  it "Enforces validation rules when rights_type is license" do
    
    opts = {:rights_type => 'license', 
            :ip_status => nil, 
            :jurisdiction => nil,
            }
            
    expect { create_rights_statement(opts) }.to raise_error(JSONModel::ValidationException)

    opts[:license_identifier_terms] = generate(:alphanumstr)

    expect { create_rights_statement(opts) }.to_not raise_error
  end

  it "Allows a rights statement to be created with an external document" do
    
    opts = {:external_documents => [build(:json_external_document)]}
    
    rights_statement = create_rights_statement(opts)

    RightsStatement[rights_statement[:id]].external_document.length.should eq(1)
    RightsStatement[rights_statement[:id]].external_document[0].title.should eq(opts[:external_documents][0]['title'])
  end


  it "will generate a ref_id if non is provided" do
    rights_statement = create_rights_statement(:identifier => nil)

    RightsStatement[rights_statement[:id]].identifier.should_not be_nil
  end

end
