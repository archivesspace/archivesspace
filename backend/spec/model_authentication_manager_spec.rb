require 'spec_helper'

class MockAuthenticationSource

  def initialize(opts)
    @opts = opts
  end

  def authenticate(user, pass, callback)
    raise "Boom" if @opts[:blowup]

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


  context "Authentication" do
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


  context "Error handling" do

    it "ignores errors thrown by any single provider" do
      AppConfig.should_receive(:[]).once.
                with(:authentication_sources).
                and_return([{
                              :model => 'MockAuthenticationSource',
                              :blowup => true,
                            }, auth_source])

      # Still fine
      AuthenticationManager.authenticate("hello", "world").should_not eq(nil)
    end
  end
end
