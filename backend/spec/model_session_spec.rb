require 'spec_helper'

describe 'Session model' do

  it "stores simple strings" do
    mysession = Session.new
    id = mysession.id

    mysession["hello"] = "world"
    mysession.save

    samesession = Session.new(id)
    samesession["hello"].should eq("world")
  end


  it "handles multiple sessions" do
    session_data = {}

    100.times do |i|
      s = Session.new
      s["data"] = "Session data #{i}"
      session_data[s.id] = "Session data #{i}"
      s.save
    end

    session_data.each do |session_id, stored_data|
      s = Session.new(session_id)
      s["data"].should eq stored_data
    end
  end

end
