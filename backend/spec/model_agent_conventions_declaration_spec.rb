require_relative 'spec_helper'

describe 'AgentConventionsDeclaration model' do
  it "allows agent_conventions_declaration records to be created" do
    acd = AgentConventionsDeclaration.new(
      :name_rule => "aacr",
      :file_version_xlink_actuate_attribute => "other",
      :file_version_xlink_show_attribute => "other",
      :citation => "citation",
      :descriptive_note => "descriptive_note",
      :file_uri => "file_uri",
      :xlink_title_attribute => "xlink_title_attribute",
      :xlink_role_attribute => "xlink_role_attribute",
      :last_verified_date => Time.now,
      :agent_person_id => rand(10000))

    acd.save
    expect(acd.valid?).to eq(true)
  end


  it "requires an agent_conventions_declaration to point to an agent record" do
    acd = AgentConventionsDeclaration.new(
      :name_rule => "aacr",
      :file_version_xlink_actuate_attribute => "other",
      :file_version_xlink_show_attribute => "other",
      :citation => "citation",
      :descriptive_note => "descriptive_note",
      :file_uri => "file_uri",
      :xlink_title_attribute => "xlink_title_attribute",
      :xlink_role_attribute => "xlink_role_attribute",
      :last_verified_date => Time.now)

    expect(acd.valid?).to eq(false)
  end

  it "is invalid if an agent_conventions_declaration points to more than one agent record" do
    acd = AgentConventionsDeclaration.new(
      :name_rule => "aacr",
      :file_version_xlink_actuate_attribute => "other",
      :file_version_xlink_show_attribute => "other",
      :citation => "citation",
      :descriptive_note => "descriptive_note",
      :file_uri => "file_uri",
      :xlink_title_attribute => "xlink_title_attribute",
      :xlink_role_attribute => "xlink_role_attribute",
      :last_verified_date => Time.now,
      :agent_person_id => rand(10000),
      :agent_family_id => rand(10000))

    expect(acd.valid?).to eq(false)
  end
end
