require 'nokogiri'

module ExportHelpers
  
  def serialize(id, type, repo_id)
    
    resource = Resource.get_or_die(id, repo_id)
    
    Log.debug("Tree #{resource.tree.inspect}")
    
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.ead {
        xml.eadHeader {
          xml.eadid "1000"
        }
        xml.archdesc {
          xml.did {
            xml.unittitle resource.title
          }
          xml.dsc {
            build_children(resource.tree, xml, repo_id)
          }
        }
      }
    end
    
    builder.to_xml
    
  end
  
  def build_children(tree, xml, repo_id)
    tree[:children].each do |t|
      id = JSONModel(:archival_object).id_for(t[:archival_object])          
      object = ArchivalObject.get_or_die(id, repo_id)
      extents = Extent.dataset.filter(:archival_object_id => id)

      Log.debug(extents.inspect)
      xml.c {
        xml.did {
          xml.unittitle object.title
          if extents
            xml.physdesc {
              extents.each do |e|
               xml.extent extent_statement(e)
              end 
            }
          end
        }
        build_children(t, xml, repo_id)
      }
      object = nil
    end
  end
  
  def xml_response(xml)
    [status, {"Content-Type" => "application/xml"}, [xml + "\n"]]
  end
  
  def extent_statement(e)
    "#{e.number} of #{e.extent_type}"
  end  
  
end