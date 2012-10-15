require 'nokogiri'

module ExportHelpers
  
  def serialize(id, type, repo_id)
    
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.ead {
        xml.eadHeader {
          xml.eadid "100"
        }
      }
    end
    
    builder.to_xml
    
  end
  
  def xml_response(xml)
    [status, {"Content-Type" => "application/xml"}, [xml + "\n"]]
  end
  
end