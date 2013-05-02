ASpaceExport::serializer :mets do
  
  def build(mets, opts = {})

    builder = Nokogiri::XML::Builder.new do |xml|
      mets(mets, xml)     
    end   
    
    builder
  end
  
  def serialize(mets, opts = {})

    builder = build(mets, opts)
    
    builder.to_xml   
  end
  
  private

  def mets(mets, xml)
    xml.mets('xmlns' => 'http://www.loc.gov/METS/', 'xmlns:mods' => 'http://www.loc.gov/mods/v3', 'xmlns:xlink' => 'http://www.w3.org/1999/xlink'){
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

      xml.fileSec { 
        if mets.file_versions
          serialize_files(mets.file_versions, xml)
        end
        
        child_files(mets.children, xml)

      }      
      
      xml.structMap {
           
      }
      
      # xml.structLink {
      #    
      #  }
      
      # xml.behaviorSec {
      #   
      # }
    }
      
  end
  
  def child_files(children, xml)    
    children.each do |child|
      if child.file_versions.length
        serialize_files(child.file_versions, xml)
      end
      child_files(child.children, xml)
    end
  end
    
  
  def serialize_files(files, xml)
    @file_id ||= 0
    xml.fileGrp {
      files.each_with_index do |file|
        @file_id += 1
        atts = {'ID' => "f#{@file_id.to_s}"}
        atts.merge({'USE' => file['use_statement']}) if file['use_statement']
        
        xml.file(atts) {
          xml.FLocat('xlink:href' => file['file_uri'], 'LOCTYPE' => 'URL') {}
        }
      end
    }
  end
    
  
end
