require_relative 'spec_helper'

describe 'AgentOtherAgencyCodes model' do
  it "allows agent_other_agency_codes records to be created" do
    aoac = AgentOtherAgencyCodes.new(:agency_code_type_enum => "oclc",
                                     :maintenance_agency => "maintenance_agency",
                                     :agent_person_id => rand(10000))

    aoac.save
    expect(aoac.valid?).to eq(true)
  end


  it "requires an agent_other_agency_codes to point to an agent record" do
  
    aoac = AgentOtherAgencyCodes.new(:agency_code_type_enum => "oclc",
                                     :maintenance_agency => "maintenance_agency")

    expect(aoac.valid?).to eq(false)
  end

  it "is invalid if an agent_other_agency_codes points to more than one agent record" do
    aoac = AgentOtherAgencyCodes.new(:agency_code_type_enum => "oclc",
                                     :maintenance_agency => "maintenance_agency",
                                     :agent_person_id => rand(10000),
                                     :agent_family_id => rand(10000))
 
    expect(aoac.valid?).to eq(false)
  end
end
