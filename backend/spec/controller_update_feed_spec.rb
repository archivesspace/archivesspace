require 'spec_helper'

describe 'Update feed controller' do

  it "blocks requests until an updated record shows up" do
    RealtimeIndexing.reset!

    consumer = Thread.new do
      as_test_user("admin") do
        get '/update-feed'
        JSON(last_response.body)
      end
    end

    created_accession = create(:json_accession)

    consumer.join
    consumer.value.count.should be == 1

    consumer.value.first['record']['title'].should eq(created_accession.title)
  end


  it "provides a feed of deleted records" do

    acc1 = create(:json_accession)
    acc1.delete
    sleep 1
    atime = Time.now
    sleep 1
    acc2 = create(:json_accession)
    acc2.delete

    resp = as_test_user("admin") do
      get "/delete-feed?page=1&modified_since=#{atime.to_i}"
      JSON(last_response.body)
    end

    resp['results'].length.should eq(1)
    resp['results'].first.should eq(acc2.uri)
  end


  it "requires special permission" do
    as_anonymous_user do
      get '/update-feed'
      last_response.should_not be_ok
      last_response.status.should eq(403)
    end
  end

end
