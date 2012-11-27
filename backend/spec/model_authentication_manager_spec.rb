require 'spec_helper'

class MockAuthenticationSource

  def initialize(opts)
    @opts = opts
  end

  def authenticate(user, pass, callback)
    user = @opts[:users][user]

    callback.call("Mark") if (user && user[:password] == pass)
  end

  def name
    "MockAuthenticationSource"
  end

end


describe 'Authentication manager' do

  let(:auth_source) do
    {
      :model => 'MockAuthenticationSource',
      :users => {
        'hello' => {:password => 'world'}
      }
    }
  end


  before(:each) do
    AppConfig.should_receive(:[]).once.
              with(:authentication_sources).
              and_return([auth_source])
  end


  it "successfully logs in to a custom provider" do
    AuthenticationManager.authenticate("hello", "world").should_not eq(nil)
  end


  it "handles failed logins against a custom provider" do
    AuthenticationManager.authenticate("hello", "wrongpass").should eq(nil)
  end

end
