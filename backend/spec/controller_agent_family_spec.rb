require 'spec_helper'

describe 'Family agent controller' do

  def create_family
    JSONModel(:agent_family).from_hash(:names => [{
                                                    "rules" => "local",
                                                    "family_name" => "Magoo Family",
                                                    "sort_name" => "Family Magoo"
                                                  }],
                                       :agent_contacts => [{
                                                              "name" => "Business hours contact",
                                                              "telephone" => "0011 1234 1234"
                                                            }]
                                       ).save
  end


  it "lets you create a family and get them back" do
    id = create_family
    JSONModel(:agent_family).find(id).names.first['family_name'].should eq('Magoo Family')
  end

  it "lets you update a family" do
    id = create_family

    family = JSONModel(:agent_family).find(id)

    family.agent_contacts << {
      "name" => "A separate contact",
      "telephone" => "0118 999 881 999 119 725 3"
    }

    family.save

    JSONModel(:agent_family).find(id).agent_contacts[1]['name'].should eq("A separate contact")

  end


end
