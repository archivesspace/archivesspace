require_relative 'spec_helper'

describe 'AgentRecordControl model' do

  it "allows agent_record_control records to be created" do
    arc = AgentRecordControl.new(:maintenance_status_enum => "new",
                                 :publication_status_enum => "in_process",
                                 :romanization_enum => "int_std",
                                 :government_agency_type_enum => "ngo",
                                 :reference_evaluation_enum => "tr_consistent",
                                 :name_type_enum => "differentiated",
                                 :level_of_detail_enum => "fully_established",
                                 :modified_record_enum => "not_modified",
                                 :cataloging_source_enum => "nat_bib_agency",
                                 :maintenance_agency => "maintenance_agency",
                                 :agency_name => "agency_name",
                                 :maintenance_agency_note => "maintenance_agency_note",
                                 :agent_person_id => rand(10000))


    arc.save
    expect(arc.valid?).to eq(true)
  end

  it "requires an agent_record_control to point to an agent record" do
    arc = AgentRecordControl.new(:maintenance_status_enum => "new")


    expect(arc.valid?).to eq(false)
  end

  it "is invalid if an agent_record_control points to more than one agent record" do
    arc = AgentRecordControl.new(:maintenance_status_enum => "new",
                                 :agent_person_id => rand(10000),
                                 :agent_family_id => rand(10000))

    expect(arc.valid?).to eq(false)
  end
end
