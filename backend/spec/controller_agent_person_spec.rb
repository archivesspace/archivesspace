require 'spec_helper'

describe 'Person agent controller' do

  def create_person
    JSONModel(:agent_person).from_hash(:names => [{
                                                    :authority_id => 'authid',
                                                    :primary_name => 'Magus Magoo'
                                                  }],
                                       :contact_details => [{
                                                              "name" => "Business hours contact",
                                                              "telephone" => "0011 1234 1234"
                                                            }]
                                       ).save
  end


  it "lets you create a person and get them back" do
    id = create_person
    JSONModel(:agent_person).find(id).names.first['primary_name'].should eq('Magus Magoo')
  end

end
