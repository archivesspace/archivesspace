require 'rails'
require 'spec_helper'
require 'rails_helper'

describe "RequiredFields model" do

  let(:requirements_model) {
    RequiredFields.new(
      JSONModel(:required_fields).from_hash({
                                              repo_id: JSONModel.repository,
                                              record_type: "agent_person",
                                              subrecord_requirements: [
                                                {
                                                  record_type: "metadata_rights_declaration",
                                                  property: "metadata_rights_declarations",
                                                  required_fields: ["xlink_title_attribute", "xlink_role_attribute"],
                                                  required: true
                                                },
                                                {
                                                  record_type: "agent_maintenance_history",
                                                  property: "agent_maintenance_histories",
                                                  required_fields: ["descriptive_note"] }
                                              ]
                                            }))
  }

  let(:agent_person_missing_subrecord) {
    build(:json_agent_person,
          :metadata_rights_declarations => nil)
  }

  let(:agent_person_missing_subrecord_fields) {
    build(:json_agent_person, {
            :metadata_rights_declarations => [build(:json_metadata_rights_declaration,
                                                    {
                                                      :xlink_title_attribute => nil,
                                                      :xlink_role_attribute => nil
                                                    })],
            :agent_maintenance_histories => [build(:json_agent_maintenance_history,
                                                   :descriptive_note => nil
                                                  )]
          })
  }

  let(:required_fields) { RequiredFields.get("agent_person") }

  it "adds appropriate errors to an object with deficiencies" do
    allow(RequiredFields).to receive(:get).with("agent_person").and_return(requirements_model)
    required_fields.add_errors(agent_person_missing_subrecord)
    expect(agent_person_missing_subrecord._exceptions[:errors]).to eq({
                                                                        "metadata_rights_declarations"=>["Subrecord is required but was missing"],
                                                                      })

    required_fields.add_errors(agent_person_missing_subrecord_fields)
    expect(agent_person_missing_subrecord_fields._exceptions[:errors]).to eq({
                                                                        "metadata_rights_declarations/0/xlink_title_attribute"=>["Property is required but was missing"],
                                                                        "metadata_rights_declarations/0/xlink_role_attribute"=>["Property is required but was missing"],
                                                                        "agent_maintenance_histories/0/descriptive_note"=>["Property is required but was missing"],
                                                                      })

  end

  it "can tell you if a subrecord is required as a given property" do
    allow(RequiredFields).to receive(:get).with("agent_person").and_return(requirements_model)
    expect(required_fields.required?("metadata_rights_declarations", "metadata_rights_declaration", "xlink_title_attribute")).to be true
    expect(required_fields.required?("agent_maintenance_histories", "agent_maintenance_history", )).not_to be true
  end

  it "can tell you if a field is required for a given property / record type" do
    allow(RequiredFields).to receive(:get).with("agent_person").and_return(requirements_model)
    expect(required_fields.required?("metadata_rights_declarations", "metadata_rights_declaration", "xlink_title_attribute")).to be true
  end


  it "can tell you if a field is required for a given property / record type even if the stored requirements lack types" do
    requirements_without_types = RequiredFields.new(
      JSONModel(:required_fields).from_hash({
                                              repo_id: JSONModel.repository,
                                              record_type: "agent_person",
                                              subrecord_requirements: [
                                                {
                                                  property: "metadata_rights_declarations",
                                                  required_fields: ["xlink_title_attribute", "xlink_role_attribute"],
                                                  required: true
                                                }
                                              ]
                                            }))
    allow(RequiredFields).to receive(:get).with("agent_person").and_return(requirements_without_types)
    expect(required_fields.required?("metadata_rights_declarations", "metadata_rights_declaration", "xlink_title_attribute")).to be true
  end
end
