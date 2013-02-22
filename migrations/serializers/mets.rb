ASpaceExport::serializer :mets do
    
  include JSONModel

  
  def build(mets, opts = {})

    builder = Nokogiri::XML::Builder.new do |xml|
      # self.wrap_builder(xml)
      # _mets(mets, xml)
      _mets(mets, xml)     
    end   
    
    builder
  end
  
  def serialize(mets, opts = {})

    builder = build(mets, opts)
    
    builder.to_xml   
  end
  
  private

  def _mets(mets, xml)
    xml.mets('xmlns' => 'http://www.loc.gov/METS/', 'xmlns:mods' => 'http://www.loc.gov/mods/v3'){
      xml.metsHdr {
        xml.agent(:ROLE => mets.header_agent_role, :TYPE => mets.header_agent_type) {
          xml.name mets.header_agent_name
          xml.note mets.header_agent_note
        }
        
      }
      
      xml.dmdSec(:ID => 'DMDSEC') {
        mets.wrapped_dmd.each do |dmd|
          xml.mdWrap(:MDTYPE => dmd['type']) {
            xml.xmlData {
              dmd['callback'].call(dmd['data'], xml) 
            }
          }
        end
      }
      
      xml.amdSec {
        
      }

      # TODO once Digital Objects have URIs:
      
      # xml.fileSec {
      #   
      # }
      
      # xml.structMap {
      #      
      #    }
      
      # xml.structLink {
      #    
      #  }
      
      # xml.behaviorSec {
      #   
      # }
    }
      
  end
end
