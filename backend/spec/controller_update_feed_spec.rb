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
    expect(consumer.value.count).to eq(1)

    expect(consumer.value.first['record']['title']).to eq(created_accession.title)
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

    expect(resp['results'].length).to eq(1)
    expect(resp['results'].first).to eq(acc2.uri)
  end


  it "requires special permission" do
    as_anonymous_user do
      get '/update-feed'
      expect(last_response).not_to be_ok
      expect(last_response.status).to eq(403)
    end
  end

end
