require 'spec_helper'

describe 'Person agent controller' do

  def create_person(opts = {})
    create(:json_agent_person, opts)
  end


  it "lets you create a person and get them back" do
    opts = {:names => [build(:json_name_person).to_hash]}

    id = create_person(opts).id
    JSONModel(:agent_person).find(id).names.first['primary_name'].should eq(opts[:names][0]['primary_name'])
  end


  it "lets you update someone by adding contacts" do
    id = create_person(:agent_contacts => nil).id

    person = JSONModel(:agent_person).find(id)
    [0, 1].each do |n|
      opts = {:name => generate(:generic_name)}

      person.agent_contacts << build(:json_agent_contact, opts).to_hash

      person.save

      JSONModel(:agent_person).find(id).agent_contacts[n]['name'].should eq(opts[:name])
    end
  end


  it "can give a list of person agents" do
    create_person
    create_person

    JSONModel(:agent_person).all(:page => 1)['results'].count.should eq(2)
  end

end
