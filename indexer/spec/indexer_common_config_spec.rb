require_relative 'spec_helper'
require_relative '../app/lib/indexer_common_config'

describe "indexer common config" do
  before(:all) do
    @record_types = IndexerCommonConfig.record_types
    @global_types = IndexerCommonConfig.global_types
    @resolved_attributes = IndexerCommonConfig.resolved_attributes
  end
  describe "record_types" do
    it "has the correct number of record_types" do
      expect(@record_types.length).to eq(17)
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
      expect(@resolved_attributes.length).to eq(14)
    end
    it "has the correct resolved_attributes" do
      expect(@resolved_attributes).to include('location_profile')
      expect(@resolved_attributes).to include('container_profile')
      expect(@resolved_attributes).to include('container_locations')
      expect(@resolved_attributes).to include('subjects')
      expect(@resolved_attributes).to include('linked_agents')
      expect(@resolved_attributes).to include('linked_records')
      expect(@resolved_attributes).to include('classifications')
      expect(@resolved_attributes).to include('digital_object')
      expect(@resolved_attributes).to include('agent_representation')
      expect(@resolved_attributes).to include('repository')
      expect(@resolved_attributes).to include('repository::agent_representation')
      expect(@resolved_attributes).to include('related_agents')
      expect(@resolved_attributes).to include('top_container')
      expect(@resolved_attributes).to include('top_container::container_profile')
    end
    it "does not include any blank values" do
      expect(@resolved_attributes).not_to include("")
    end
  end
end
