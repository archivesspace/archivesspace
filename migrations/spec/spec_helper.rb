require 'net/http'
require 'psych'
require 'nokogiri'
require_relative "../../common/jsonmodel"
require_relative "../lib/jsonmodel_queue"
require_relative "../lib/crosswalk.rb"


class Net::HTTP
  
  def request(req)
    puts "(Mock) #{req.class.name} #{req.body.to_s}"
    StubHTTP.new
  end

end

class StubHTTP
  
  def code
    "200"
  end
  
  def body
    res_body = { 'id' => (0..3).map{ rand(10) }.join }.to_json
    puts "(Mock) Response Body #{res_body}"
    res_body
  end
end

class Klass
  include JSONModel
end

def make_test_schema
  '{
    :schema => {
      "$schema" => "http://www.archivesspace.org/archivesspace.json",
      "type" => "object",
      "uri" => "/repositories/:repo_id/stubs",
      "properties" => {
        "uri" => {"type" => "string", "required" => false},
        "ref_id" => {"type" => "string", "ifmissing" => "error", "minLength" => 1, "pattern" => "^[a-zA-Z0-9]*$"},
        "component_id" => {"type" => "string", "required" => false, "default" => "", "pattern" => "^[a-zA-Z0-9]*$"},
        "title" => {"type" => "string", "minLength" => 1, "required" => true},

        "level" => {"type" => "string", "minLength" => 1, "required" => false},
        "parent" => {"type" => "JSONModel(:stub) uri", "required" => false},
        "collection" => {"type" => "JSONModel(:stub) uri", "required" => false},

        "subjects" => {"type" => "array", "items" => {"type" => "JSONModel(:stub) uri_or_object"}},
      },

      "additionalProperties" => false,
    },
  }'
end

def make_body_part_schema
  '{
    :schema => {
      "$schema" => "http://www.archivesspace.org/archivesspace.json",
      "type" => "object",
      "uri" => "/repositories/:repo_id/body_part",
      "properties" => {
        "uri" => {"type" => "string", "required" => false},
        "name" => {"type" => "string", "minLength" => 1, "required" => true},
        "location" => {"type" => "JSONModel(:body_part) uri", "required" => false},
      },
      "additionalProperties" => false,
    },
  }'
end


def make_test_crosswalk
  Psych.dump({
              'source' => {
                'format' => 'xml',
                'schema' => 'human_body'
              },
              'entities' => {
                'body_part' => {
                  'instance' => ['//muscle', '//limb', '//joint'],
                  'properties' => {'name' => ['@type'], 'location' => ['parent::limb', 'parent::joint']}
                }
              }
            })
end



def make_test_xml
  builder = Nokogiri::XML::Builder.new do |xml|
    xml.body(:type => "human") {
      xml.head {
        xml.muscle(:type => "brain")
      }
      xml.torso {
        xml.limb(:type => "arm") {
          xml.muscle(:type => "bicep")
          xml.joint(:type => "shoulder") {
            xml.muscle(:type => "deltoid")
          }
        }
      }
    }
  end
    builder.to_xml
end
# 
# puts make_test_xml
# puts make_test_crosswalk