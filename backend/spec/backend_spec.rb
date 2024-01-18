require 'spec_helper'

describe 'The ArchivesSpaceService app' do

  it "says hello" do
    get '/'
    expect(last_response).to be_ok
  end


  it "gives you TMI if you ask in JSON" do
    get '/', nil, {'HTTP_ACCEPT' => "application/json"}
    expect(last_response).to be_ok
    json = JSON.parse(last_response.body)
    expect(( json.keys - DB.sysinfo.keys).empty?).to be_truthy
  end

end
