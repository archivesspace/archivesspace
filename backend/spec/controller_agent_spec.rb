require 'spec_helper'

describe 'Generic agent controller' do

  it "lets you list all agents of any type" do
    [
      :agent_person, 
      :agent_family, 
      :agent_software, 
      :agent_corporate_entity
    ].each do |a_type|
      
      JSONModel.all('/agents', :agent_type).map {|agent| agent.agent_type }.should_not include(a_type.to_s)

      create("json_#{a_type.to_s}".to_sym)

      JSONModel.all('/agents', :agent_type).map {|agent| agent.agent_type }.should include(a_type.to_s)
    end

  end

end
