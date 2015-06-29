require 'spec_helper'

describe 'The ArchivesSpaceService app' do

  it "says hello" do
    get '/'
    last_response.should be_ok
  end
  

  it "gives you TMI if you ask in JSON" do
    get '/', nil, {'HTTP_ACCEPT' => "application/json"}
    last_response.should be_ok
    json = JSON.parse(last_response.body)
    ( json.keys - [ "databaseProductName", "databaseProductVersion", "ruby_version",
                    "host_os", "host_cpu", "build", "archivesSpaceVersion"] ).empty?.should be_truthy
  end

end
