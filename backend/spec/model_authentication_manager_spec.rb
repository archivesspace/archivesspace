require 'spec_helper'

class MockAuthenticationSource
  include JSONModel

  def initialize(opts)
    @opts = opts
  end

  def authenticate(username, pass)
    raise "Boom" if @opts[:blowup]

    user = @opts[:users][username]

    if (user && user[:password] == pass)
      JSONModel(:user).from_hash(:username => username, :name => "Mark")
    end
  end


  def matching_usernames(query)
    @opts[:users].keys.select {|username| username =~ /^#{query}/}
  end


  def name
    "MockAuthenticationSource"
  end
end


describe 'Authentication manager' do

  let(:username) { "hello-#{Time.now.to_i}" }
  let(:auth_source) do
    {
      :model => 'MockAuthenticationSource',
      :users => {
        username => {:password => 'world'}
      }
    }
  end
  let(:also_a_db_user) {
    user = build(:json_user, username: username)
    user.save(:password => 'backdoor')
    User.find(username: username).update(source: "MockAuthenticationSource")
    user
  }


  context "Authentication" do
    before(:each) do
      AppConfig[:authentication_sources] = [auth_source]
    end


    it "successfully logs in to a custom provider" do
      expect(AuthenticationManager.authenticate(username, "world")).not_to be_nil
    end


    it "handles failed logins against a custom provider" do
      expect(AuthenticationManager.authenticate(username, "wrongpass")).to be_nil
    end


    it "successfully logs a user in if any provider permits it" do
      AppConfig[:authentication_restricted_by_source] = false
      also_a_db_user
      expect(AuthenticationManager.authenticate(username, "wrongpass")).to be_nil
      expect(AuthenticationManager.authenticate(username, "backdoor")).not_to be_nil
      expect(User.find(username: username).source).to eq('DBAuth')
    end


    it "prevents login from another provider if source restriction is enabled" do
      AppConfig[:authentication_restricted_by_source] = true
      also_a_db_user
      expect(AuthenticationManager.authenticate(username, "wrongpass")).to be_nil
      expect(AuthenticationManager.authenticate(username, "backdoor")).to be_nil
      expect(AuthenticationManager.authenticate(username, "world")).not_to be_nil
      expect(User.find(username: username).source).to eq('MockAuthenticationSource')
    end


    it "handles lots of simultaneous logins for the same user with grace" do

      # Create the user initially since we're not worried about user creation
      # here.
      #
      # Funny thread trickery here to give us a separate DB connection.
      # Otherwise we end up creating and locking the user row in the DB, which
      # cauess the tests to deadlock.
      Thread.new do
        AuthenticationManager.authenticate(username, "world")
      end.join

      threads = (0...4).map do
        Thread.new do
          50.times.map { AuthenticationManager.authenticate(username, "world") }
        end
      end

      expect(threads.map(&:value).flatten.find_all(&:nil?).count).to eq(0)
    end

  end


  context "Search" do
    before(:each) do
      AppConfig[:authentication_sources] = [auth_source]
    end


    it "can find a matching user" do
      expect(AuthenticationManager.matching_usernames("hel")).to eq([username])
    end

    it "can handle no matches" do
      expect(AuthenticationManager.matching_usernames("garbage")).to eq([])
    end
  end


  context "Error handling" do

    it "ignores errors thrown by any single provider" do
      AppConfig[:authentication_sources] = [
                                             {
                                               :model => 'MockAuthenticationSource',
                                               :blowup => true,
                                             },
                                            auth_source
                                            ]

      # Still fine
      expect(AuthenticationManager.authenticate(username, "world")).not_to be_nil
    end
  end

  context "Lost passwords" do

    it "can generate and authenticate an expiring, single-use token" do
      username = "forgetful"
      password = "iforget"
      user = build(:json_user, username: username)
      user.save(password: password)

      token = AuthenticationManager.generate_token(username)
      expect(AuthenticationManager.authenticate_token(username, token)).not_to be_nil
      # token is single-use
      expect(AuthenticationManager.authenticate_token(username, token)).to be_nil
      # so let's get a new one
      token = AuthenticationManager.generate_token(username)
      expect(AuthenticationManager.authenticate_token(username, token)).not_to be_nil
      # now get one and wait 5 minutes
      token = AuthenticationManager.generate_token(username)
      time_now = Time.now
      allow(Time).to receive(:now).and_return(time_now + 30*60)
      expect(AuthenticationManager.authenticate_token(username, token)).to be_nil
      # now go back in time 5 seconds
      allow(Time).to receive(:now).and_return(time_now + (5*60)-5)
      expect(AuthenticationManager.authenticate_token(username, token)).not_to be_nil
    end
  end
end
