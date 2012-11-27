require 'spec_helper'

class MockAuthenticationSource

  def initialize(opts)
    @opts = opts
  end

  def authenticate(user, pass)
    user = @opts[:users][user]

    user if (user && user[:password] == pass)
  end

end


describe 'Authentication manager' do

  it "Can be configured to authenticate against a custom provider" do
    auth_source = {
      :model => 'MockAuthenticationSource',
      :users => {
        'hello' => {:password => 'world'}
      }
    }

    AppConfig.should_receive(:[]).twice.
              with(:authentication_sources).
              and_return([auth_source])

    AuthenticationManager.authenticate("hello", "wrongpass").should eq(nil)
    AuthenticationManager.authenticate("hello", "world").should_not eq(nil)
  end

end
