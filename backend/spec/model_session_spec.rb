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


  it "knows its age" do
    allow(Time).to receive(:now) { Time.at(0) }
    s = Session.new
    allow(Time).to receive(:now) { Time.at(10) }
    s.age.should eq(10)
  end


  it "becomes young again when touched" do
    allow(Time).to receive(:now) { Time.at(0) }
    s = Session.new
    allow(Time).to receive(:now) { Time.at(10) }
    s.touch
    allow(Time).to receive(:now) { Time.at(100) }
    s.age.should eq(90)
    allow(Time).to receive(:now) { Time.at(110) }
    s.touch
    allow(Time).to receive(:now) { Time.at(111) }
    s.age.should eq(1)
  end


  it "can be expired" do
    s = Session.new
    Session.expire(s.id)
    Session.find(s.id).should be_nil
  end

end
