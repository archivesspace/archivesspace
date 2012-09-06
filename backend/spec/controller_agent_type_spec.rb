require 'spec_helper'

describe 'Agent Type controller' do

  it "gives a list of all agent types" do
    ats = JSONModel(:agent_type).all

    ats.any? { |at| at.label == "Person" }.should be_true
    ats.any? { |at| at.label == "Family" }.should be_true
    ats.any? { |at| at.label == "Corporate Entity" }.should be_true
    ats.any? { |at| at.label == "Software" }.should be_true

  end

  it "can give the label for an agent type id" do
    JSONModel(:agent_type).find(1).label.should match(/(Person|Family|Corporate Entity|Software)/)
  end


end
