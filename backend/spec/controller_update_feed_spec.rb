require 'spec_helper'

describe 'Update feed controller' do

  before(:each) do
    # Cheat here and clear directly before our test
    RealtimeIndexing.reset!
  end

  let!(:created_accession) { create(:json_accession) }



  it "blocks requests until an updated record shows up" do
    consumer = Thread.new do
      as_test_user("admin") do
        get '/update-feed'
        JSON(last_response.body)
      end
    end

    consumer.join
    consumer.value.count.should be == 1

    consumer.value.first['record']['title'].should eq(created_accession.title)
  end


  it "requires special permission" do
    as_anonymous_user do
      get '/update-feed'
      last_response.should_not be_ok
      last_response.status.should eq(403)
    end
  end

end
