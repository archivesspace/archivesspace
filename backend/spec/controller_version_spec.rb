require 'spec_helper'

describe 'Version controller' do

  it "tells you what version you're running" do
    response = get "/version"
    expect(response.body).to eq "ArchivesSpace (#{ASConstants.VERSION})"
  end

end
