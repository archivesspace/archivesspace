require_relative 'spec_helper'

describe 'AgentMaintenanceHistory model' do
  it "allows agent_maintenance_history records to be created" do
    amh = AgentMaintenanceHistory.new(
      :maintenance_event_type_enum => "created",
      :maintenance_agent_type_enum => "human",
      :event_date => Time.now,
      :agent => "agent",
      :descriptive_note => "descriptive_note",
      :agent_person_id => rand(10000))

    amh.save
    expect(amh.valid?).to eq(true)
  end


  it "requires an agent_maintenance_history to point to an agent record" do
  
    amh = AgentMaintenanceHistory.new(
      :maintenance_event_type_enum => "created",
      :maintenance_agent_type_enum => "human",
      :event_date => Time.now,
      :agent => "agent",
      :descriptive_note => "descriptive_note")

    expect(amh.valid?).to eq(false)
  end

  it "is invalid if an agent_maintenance_history points to more than one agent record" do
    amh = AgentMaintenanceHistory.new(
      :maintenance_event_type_enum => "created",
      :maintenance_agent_type_enum => "human",
      :event_date => Time.now,
      :agent => "agent",
      :descriptive_note => "descriptive_note",
      :agent_person_id => rand(10000),
      :agent_family_id => rand(10000))
 
    expect(amh.valid?).to eq(false)
  end
end
