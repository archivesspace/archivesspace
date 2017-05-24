require 'spec_helper'

describe 'Session model' do

  it "stores simple strings" do
    mysession = Session.new
    id = mysession.id

    mysession["hello"] = "world"
    mysession.save

    samesession = Session.find(id)
    samesession["hello"].should eq("world")
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
      s["data"].should eq stored_data
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

    (next_age - first_age).abs.should eq(10)
  end


  it "can be expired" do
    s = Session.new
    Session.expire(s.id)
    Session.find(s.id).should be_nil
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
    Session.find(short_session.id).should be_nil
    Session.find(long_session.id).should_not be_nil
  end

  it "expires non-expirable sessions after :session_nonexpirable_force_expire_after_seconds" do
    long_session = Session.new

    long_session[:expirable] = false

    long_session.save

    allow(AppConfig).to receive(:[]).with(any_args)
    allow(AppConfig).to receive(:[]).with(:session_nonexpirable_force_expire_after_seconds) { 0 }

    sleep 1

    Session.expire_old_sessions
    Session.find(long_session.id).should be_nil
  end

end
