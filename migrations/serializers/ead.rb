require 'nokogiri'

ASpaceExport::serializer :ead do
  
  def serialize(object, opts = {})

    raise StandardError.new("Can't serialize a #{object.class}") unless object.class.to_s.match(/Resource/)

    builder = Nokogiri::XML::Builder.new do |xml|
      _ead(object, xml)     
    end
    
    builder.to_xml   
  end
  
  private
  
  def _ead(object, xml)  
    Log.debug("Resource #{object.values}")
    xml.ead {
      _ead_header(object, xml)
      _archdesc(object,xml)
    }
  end
  
  def _ead_header(object, xml)
    xml.eadHeader {
      xml.eadid object.identifier
    }
  end
  
  def _archdesc(object,xml)
    xml.archdesc {
      xml.did {
        xml.unittitle object.title
        xml.unitid object.identifier
        extents = Extent.dataset.filter(:resource_id => object.id)
        if extents
          xml.physdesc {
            extents.each do |e|
              _extent_statement(e, xml)
            end 
          }
        end  
      }
      xml.dsc {
        if (tree = object.tree)
          _desc_tree(tree, xml)
        end
      }
    }
  end

  def _desc_tree(tree, xml)
    return unless tree['children']
    
    tree['children'].each do |t|
      id = JSONModel::JSONModel(:archival_object).id_for(t['archival_object'])          
      object = ArchivalObject.get_or_die(id)
      _c(object, t, xml)
    end
  end
  
  def _c(object, tree, xml)
    
    xml.c(:id => object.ref_id) {      
      _did(object, xml)
      _desc_tree(tree, xml)
    }
  end
  
  def _did(object, xml)
    extents = Extent.dataset.filter(:archival_object_id => object.id)
    
    xml.did {
      xml.unittitle object.title
      if extents
        xml.physdesc {
          extents.each do |e|
            _extent_statement(e, xml)
          end 
        }
      end
    }
  end

  def _extent_statement(e, xml)
    xml.extent "#{e.number} of #{e.extent_type}"
  end 
end
