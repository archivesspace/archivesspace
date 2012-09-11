require 'spec_helper'

describe 'Person agent controller' do

  def create_person
    JSONModel(:agent_person).from_hash(:names => [{
                                                    :authority_id => 'authid',
                                                    :primary_name => 'Magus Magoo'
                                                  }],
                                       :agent_contacts => [{
                                                              "name" => "Business hours contact",
                                                              "telephone" => "0011 1234 1234"
                                                            }]
                                       ).save
  end


  it "lets you create a person and get them back" do
    id = create_person
    JSONModel(:agent_person).find(id).names.first['primary_name'].should eq('Magus Magoo')
  end

  it "lets you update someone" do
    id = create_person

    person = JSONModel(:agent_person).find(id)

    person.agent_contacts << {
      "name" => "A separate contact",
      "telephone" => "0118 999 881 999 119 725 3"
    }

    person.save

    JSONModel(:agent_person).find(id).agent_contacts[1]['name'].should eq("A separate contact")

  end


end
