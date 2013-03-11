require 'spec_helper'

describe 'Person agent controller' do

  def create_person(opts = {})
    create(:json_agent_person, opts)
  end


  it "lets you create a person and get them back" do
    opts = {:names => [build(:json_name_person)]}

    id = create_person(opts).id
    JSONModel(:agent_person).find(id).names.first['primary_name'].should eq(opts[:names][0]['primary_name'])
  end


  it "lets you update someone by adding contacts" do
    id = create_person(:agent_contacts => nil).id

    person = JSONModel(:agent_person).find(id)
    [0, 1].each do |n|
      opts = {:name => generate(:generic_name)}

      person.agent_contacts << build(:json_agent_contact, opts)

      person.save

      JSONModel(:agent_person).find(id).agent_contacts[n]['name'].should eq(opts[:name])
    end
  end


  it "can give a list of person agents" do
    
    start = JSONModel(:agent_person).all(:page => 1)['results'].count
    
    2.times { create_person }
    
    JSONModel(:agent_person).all(:page => 1)['results'].count.should eq(start+2)
  end


  it "sets the sort name if one is provided" do
    opts = {:names => [build(:json_name_person, :sort_name => "Custom Sort Name", :sort_name_auto_generate => false)]}

    id = create_person(opts).id
    JSONModel(:agent_person).find(id).names.first['sort_name'].should eq(opts[:names][0]['sort_name'])
  end


  it "auto-generates the sort name if one is not provided" do
    id = create_person({:names => [build(:json_name_person,{:primary_name => "Hendrix", :rest_of_name => "Jimi", :title => "Mr", :name_order => "direct", :sort_name_auto_generate => true})]}).id

    agent = JSONModel(:agent_person).find(id)

    agent.names.first['sort_name'].should eq("Jimi Hendrix, Mr")

    agent.names.first['name_order'] = "direct"
    agent.save

    JSONModel(:agent_person).find(id).names.first['sort_name'].should eq("Jimi Hendrix, Mr")
  end

end
