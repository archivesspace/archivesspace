require 'spec_helper'

describe 'The ArchivesSpaceService app' do

  it "says hello" do
    get '/'
    last_response.should be_ok
    last_response.body.should == 'Hello, ArchivesSpace!'
  end

end
