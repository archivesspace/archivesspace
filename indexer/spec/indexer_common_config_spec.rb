require 'spec_helper'
require_relative '../app/lib/indexer_common_config'

describe "indexer common config" do
  before(:all) do
    @record_types = IndexerCommonConfig.record_types
    @global_types = IndexerCommonConfig.global_types
    @resolved_attributes = IndexerCommonConfig.resolved_attributes
  end
  describe "record_types" do
    it "has the correct number of record_types" do
      expect(@record_types.length).to eq(19)
    end
    it "has the correct record_types" do
      expect(@record_types).to include(:resource)
      expect(@record_types).to include(:digital_object)
      expect(@record_types).to include(:accession)
      expect(@record_types).to include(:agent_person)
      expect(@record_types).to include(:agent_software)
      expect(@record_types).to include(:agent_family)
      expect(@record_types).to include(:agent_corporate_entity)
      expect(@record_types).to include(:subject)
      expect(@record_types).to include(:location)
      expect(@record_types).to include(:event)
      expect(@record_types).to include(:top_container)
      expect(@record_types).to include(:classification)
      expect(@record_types).to include(:container_profile)
      expect(@record_types).to include(:location_profile)
      expect(@record_types).to include(:archival_object)
      expect(@record_types).to include(:digital_object_component)
      expect(@record_types).to include(:classification_term)
      expect(@record_types).to include(:assessment)
      expect(@record_types).to include(:job)
    end
    it "does not include any blank values" do
      expect(@record_types).not_to include("")
    end
  end
  describe "global_types" do
    it "has the correct number of global_types" do
      expect(@global_types.length).to eq(6)
    end
    it "has the correct global_types" do
      expect(@global_types).to include(:agent_person)
      expect(@global_types).to include(:agent_software)
      expect(@global_types).to include(:agent_family)
      expect(@global_types).to include(:agent_corporate_entity)
      expect(@global_types).to include(:location)
      expect(@global_types).to include(:subject)
    end
    it "does not include any blank values" do
      expect(@global_types).not_to include("")
    end
  end
  describe "resolved_attributes" do
    it "has the correct number of resolved_attributes" do
      expect(@resolved_attributes.length).to eq(20)
    end
    it "has the correct resolved_attributes" do
      attrs = %w( location_profile container_profile container_locations subjects
          linked_agents linked_records classifications digital_object agent_representation
          repository repository::agent_representation related_agents top_container
          top_container::container_profile related_agents
          records collections surveyed_by reviewer )
      expect(attrs.length).to eq(19)
      attrs.each { |attr| expect(@resolved_attributes).to include(attr) }
    end
    it "does not include any blank values" do
      expect(@resolved_attributes).not_to include("")
    end
  end
end
