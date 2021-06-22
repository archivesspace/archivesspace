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

  it "reloads app configuration" do
    config_test_file = Tempfile.new('test_config')

    old_page_size = AppConfig[:default_page_size]
    new_page_size = old_page_size += 5

    ENV['ASPACE_CONFIG'] = config_test_file.path

    config_test_file << "AppConfig[:default_page_size] = #{new_page_size}"
    config_test_file.flush
    config_test_file.close

    resp = as_test_user("admin") do
      post "/system/config"
    end

    expect(AppConfig[:default_page_size]).to eq(new_page_size)
  end


end
