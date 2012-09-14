require 'spec_helper'

describe 'Corporate entity agent controller' do

  def create_corporate_entity
    JSONModel(:agent_corporate_entity).from_hash(:names => [{
                                                    "authority_id" => "something",
                                                    "primary_name" => "Magoo Incorporated",
                                                    "sort_name" => "Corporate_Entity Magoo"
                                                  }],
                                       :agent_contacts => [{
                                                              "name" => "Business hours contact",
                                                              "telephone" => "0011 1234 1234"
                                                            }]
                                       ).save
  end


  it "lets you create a corporate entity and get it back" do
    id = create_corporate_entity
    JSONModel(:agent_corporate_entity).find(id).names.first['primary_name'].should eq('Magoo Incorporated')
  end

  it "lets you update a corporate_entity" do
    id = create_corporate_entity

    corporate_entity = JSONModel(:agent_corporate_entity).find(id)

    corporate_entity.agent_contacts << {
      "name" => "A separate contact",
      "telephone" => "0118 999 881 999 119 725 3"
    }

    corporate_entity.save

    JSONModel(:agent_corporate_entity).find(id).agent_contacts[1]['name'].should eq("A separate contact")

  end


end
