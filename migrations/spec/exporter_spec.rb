require_relative "spec_helper"
require 'nokogiri'

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


describe "ASpaceExport::Serializer::EadSerializer" do
  
  it "should be able to serialize a Resource record" do
    r = create_resource
    ead = ASpaceExport::Serializer(:ead).serialize(r)
    
    puts ead.to_s
    
  end
end

