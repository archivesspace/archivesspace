require 'spec_helper'

describe 'Session model' do

  it "stores simple strings" do
    mysession = Session.new
    id = mysession.id

    mysession["hello"] = "world"
    mysession.save

    samesession = Session.find(id)
    expect(samesession["hello"]).to eq("world")
  end


  it "handles multiple sessions" do
    session_data = {}

    10.times do |i|
      s = Session.new
      s["data"] = "Session data #{i}"
      session_data[s.id] = "Session data #{i}"
      s.save
    end

    session_data.each do |session_id, stored_data|
      s = Session.find(session_id)
      expect(s["data"]).to eq stored_data
    end
  end


  it "becomes young again when touched" do
    first_time = Time.at(0)
    next_time = Time.at(10)

    s = Session.new

    s.touch; Session.touch_pending_sessions(first_time)
    first_age = Session.find(s.id).age

    s.touch; Session.touch_pending_sessions(next_time)
    next_age = Session.find(s.id).age

    expect((next_age - first_age).abs).to eq(10)
  end


  it "can be expired" do
    s = Session.new
    Session.expire(s.id)
    expect(Session.find(s.id)).to be_nil
  end

  it "expires expirable sessions after :session_expire_after_seconds" do
    short_session = Session.new
    long_session = Session.new

    short_session[:expirable] = true
    long_session[:expirable] = false

    short_session.save
    long_session.save

    allow(AppConfig).to receive(:[]).with(any_args)
    allow(AppConfig).to receive(:[]).with(:session_expire_after_seconds) { 0 }

    sleep 1

    Session.expire_old_sessions
    expect(Session.find(short_session.id)).to be_nil
    expect(Session.find(long_session.id)).not_to be_nil
  end

  it "expires non-expirable sessions after :session_nonexpirable_force_expire_after_seconds" do
    long_session = Session.new

    long_session[:expirable] = false

    long_session.save

    allow(AppConfig).to receive(:[]).with(any_args)
    allow(AppConfig).to receive(:[]).with(:session_nonexpirable_force_expire_after_seconds) { 0 }

    sleep 1

    Session.expire_old_sessions
    expect(Session.find(long_session.id)).to be_nil
  end

  describe "a pui_only session" do
    before(:each) do
      create_user
    end

    let(:pui_only_headers) do
      session = Session.new
      session[:user] = 'test1'
      session[:pui_only] = true
      session.save

      {"HTTP_X_ARCHIVESSPACE_SESSION" => session.id}
    end

    it "is allowed to check the current user" do
      get '/users/current-user', params = {}, pui_only_headers
      expect(last_response).to be_ok
    end

    it "is allowed to log out" do
      post '/logout', params = {}, pui_only_headers
      expect(last_response).to be_ok
    end

    it "is forbidden from any other request" do
      get '/', params = {}, pui_only_headers

      expect(last_response.status).to eq(403)
      expect(JSON(last_response.body)["code"]).to eq('PUI_SESSION_FORBIDDEN')
    end
  end

  describe "a regular (non-pui_only) session" do
    it "is not restricted to the pui_only allowlist" do
      session = Session.new
      session[:user] = 'test1'
      session.save

      get '/', params = {}, {"HTTP_X_ARCHIVESSPACE_SESSION" => session.id}
      expect(last_response).to be_ok
    end
  end

end
