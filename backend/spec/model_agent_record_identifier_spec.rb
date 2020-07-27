require_relative 'spec_helper'

describe 'AgentRecordIdentifier model' do
  it "allows agent_record_identifier records to be created" do
    ari = AgentRecordIdentifier.new(
      :identifier_type_enum => "loc",
      :source_enum => "naf",
      :primary_identifier => rand(10000),
      :record_identifier => "record_identifer",
      :agent_person_id => rand(10000))

    ari.save
    expect(ari.valid?).to eq(true)
  end


  it "requires an agent_record_identifier to point to an agent record" do
  
   ari = AgentRecordIdentifier.new(
      :identifier_type_enum => "loc",
      :source_enum => "naf",
      :primary_identifier => rand(10000),
      :record_identifier => "record_identifer")

    expect(ari.valid?).to eq(false)
  end

  it "is invalid if an agent_record_identifier points to more than one agent record" do

   ari = AgentRecordIdentifier.new(
      :identifier_type_enum => "loc",
      :source_enum => "naf",
      :primary_identifier => rand(10000),
      :record_identifier => "record_identifer",
      :agent_person_id => rand(10000),
      :agent_family_id => rand(10000))
 
    expect(ari.valid?).to eq(false)
  end
end
