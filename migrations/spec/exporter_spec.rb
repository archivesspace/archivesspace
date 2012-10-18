require_relative "spec_helper"
require 'nokogiri'

describe "ASpaceExport::Serializer::EadSerializer" do
  
  before(:each) do
    @repo_id = make_test_repo
  end

  def create_resource
    Resource.create_from_json(JSONModel(:resource).
                              from_hash({
                                          "title" => "A new resource",
                                          "id_0" => "abc123",
                                          "extents" => [
                                            {
                                              "portion" => "whole",
                                              "number" => "5 or so",
                                              "extent_type" => "reels",
                                            }
                                          ]
                                        }),
                              :repo_id => @repo_id)
  end  
  
  it "should be able to convert a Resource record to an EAD" do
    r = create_resource
    ead = ASpaceExport::serializer(:ead).serialize(r)
    doc = Nokogiri::XML ead    
    doc.xpath("//unittitle").to_s.should eq '<unittitle>A new resource</unittitle>'
  end
end

