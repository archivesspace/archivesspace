require 'spec_helper'

describe 'ASModel' do

  it "knows if it is a top level model" do
    # some top level models
    expect(Repository.top_level?).to eq(true)
    expect(Accession.top_level?).to eq(true)
    expect(Resource.top_level?).to eq(true)
    expect(ArchivalObject.top_level?).to eq(true)
    expect(DigitalObject.top_level?).to eq(true)
    expect(DigitalObjectComponent.top_level?).to eq(true)
    expect(TopContainer.top_level?).to eq(true)
    expect(Location.top_level?).to eq(true)
    expect(Subject.top_level?).to eq(true)
    expect(Assessment.top_level?).to eq(true)

    # some nested models
    expect(Instance.top_level?).to eq(false)
    expect(Extent.top_level?).to eq(false)
    expect(UserDefined.top_level?).to eq(false)
    expect(SubContainer.top_level?).to eq(false)
    expect(ASDate.top_level?).to eq(false)
  end

end
