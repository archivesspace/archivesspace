require 'spec_helper'
require 'tempfile'

describe 'System controller' do

  # system events are really simple and i dont think we need a jsonmodel
  # for them. just return back a jsonized array of the values.
  it "returns a list of the systems events that have been added to the db" do

    resp = as_test_user("admin") do
      get "/system/events"
      JSON(last_response.body)
    end

    expect(resp.length).to eq(0)
  end

end
