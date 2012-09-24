require 'spec_helper'

describe 'Date model' do


  it "Allows an expression date to created" do

    date = Date.create_from_json(JSONModel(:date).
                                 from_hash({
                                             "type" => "single",
                                             "label" => "creation",
                                             "expression" => "The day before yesterday",
                                           }))

    Date[date[:id]].expression.should eq("The day before yesterday")
  end


end
