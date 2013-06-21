ASpaceExport::serializer :mods do
  
  include JSONModel
  
  def serialize(mods, opts = {})

    builder = Nokogiri::XML::Builder.new do |xml|
      _mods(mods, xml)     
    end
    
    builder.to_xml   
  end
  
  def _mods(mods, xml)
    
    root_args = {'version' => '3.4'}
    root_args['xmlns'] = 'http://www.loc.gov/mods/v3' 
    
    xml.mods(root_args){
      xml.titleInfo {
        xml.title mods.title
      }
      
      xml.typeOfResource mods.type_of_resource
      

      xml.language {
        xml.languageTerm(:type => 'code') {
          xml.text mods.language_term
        }
        
      }
      
      xml.physicalDescription{
        mods.extents.each do |extent|
          xml.extent extent
        end
      }
      
      mods.notes.each do |note|
        xml.note({:type => note['type'], :displayLabel => note['label']}) {
          xml.text ASpaceExport::Utils.extract_note_text(note)
        }
      end
      
      mods.subjects.each do |subject|
        xml.subject {
          subject['terms'].each do |term|
            xml.topic term
          end
        }
      end
      
      mods.names.each do |name|
        xml.name(:type => name['type']) {
          name['parts'].each do |part|
            if part['type']
              xml.namePart(:type => part['type']) {
                xml.text part['content']
              }
            else
              xml.namePart part['content']
            end
          end
          xml.role {
            xml.roleTerm name['role']
          }
        }
      end
      
      mods.parts.each do |part|
        xml.part(:ID => part['id']) {
          xml.detail {
            xml.title part['title']
          }
        }
      end
    }    
  end
end
