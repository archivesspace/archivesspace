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

    agent.names.first['sort_name'].should match(/\AJimi Hendrix,.* Mr/)

    agent.names.first['name_order'] = "direct"
    agent.save

    JSONModel(:agent_person).find(id).names.first['sort_name'].should match(/\AJimi Hendrix,.* Mr/)
  end


  it "allows agents to have a bioghist notes" do

    n1 = build(:json_note_bioghist)

    id = create_person({:notes => [n1]}).id

    agent = JSONModel(:agent_person).find(id)

    agent.notes.length.should eq(1)
    agent.notes[0]["label"].should eq(n1.label)
  end


  it "throws an error if created with an invalid note type" do

    n1 = build(:json_note_bibliography)

    expect { create_person({:notes => [n1.to_json]}) }.to raise_error(JSONModel::ValidationException)

  end


  it "offers a readonly 'title' of the first name's sort_name" do
    id = create_person({:names => [build(:json_name_person,{:primary_name => "Hendrix", :rest_of_name => "Jimi", :title => "Mr", :name_order => "direct", :sort_name_auto_generate => true})]}).id

    agent = JSONModel(:agent_person).find(id)

    agent.title.should match(/Jimi Hendrix,.* Mr/)
  end


  it "allows agents to have dates of existence" do

    date = build(:json_date, :label => "existence")

    id = create_person({:dates_of_existence => [date]}).id

    agent = JSONModel(:agent_person).find(id)

    agent.dates_of_existence.length.should eq(1)
    agent.dates_of_existence[0]["expression"].should eq(date.expression)
  end


  it "allows names to have use dates" do

    date = build(:json_date)

    name = build(:json_name_person, {:use_dates => [date]})

    id = create_person({:names => [name]}).id

    agent = JSONModel(:agent_person).find(id)

    agent.names[0]['use_dates'].length.should eq(1)
  end
end
