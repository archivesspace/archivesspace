require 'spec_helper'

describe 'Term controller' do

  it "returns terms matching a prefix" do
    create(:json_subject, :terms => [build(:json_term, "term" => "Prefixmatch Heroes")])

    get "/terms", :q => "prefixmatch"

    expect(last_response.status).to eq(200)
    expect(JSON(last_response.body)['results'].map {|t| t['term']}).to include("Prefixmatch Heroes")
  end

end
