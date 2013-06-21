require 'nokogiri'

ASpaceExport::serializer :ead do
  

  def serialize(ead, opts = {})
    
    builder = Nokogiri::XML::Builder.new do |xml|
    
      xml.ead('xmlns' => 'urn:isbn:1-931666-22-9', 
                 'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                 'xsi:schemaLocation' => 'http://www.loc.gov/ead/ead.xsd'){ 
                   
        xml.eadheader {
        
          xml.eadid [:id_0, :id_1, :id_2, :id_3].map {|a| ead.send(a) }.join('--')
          
          xml.filedesc {
            
            xml.titlestmt {
              
              xml.titleproper ead.title
              
            }
            
          }
        
        }
    
        xml.archdesc(:level => ead.level) {
          
          
          xml.did {
            xml.unitid [:id_0, :id_1, :id_2, :id_3].map {|a| ead.send(a) }.join('--')
            
            dates_as_unitdates(ead, xml)
             
            xml.physdesc {

              ead.extents.each do |ext|
                e = ext['number']
                e << " (#{ext['portion']})" if ext['portion']
                e << " #{ext['extent_type']}"
                xml.extent e
              end
            }
            
          }
          
          
          
          ead.notes.each do |note|

            next if note['internal']
            next unless ead.archdesc_children.include?(note['type'])

            content = ASpaceExport::Utils.extract_note_text(note)

            xml.send(note['type']) {
              xml.p content
            }
          end

          
          xml.controlaccess {
            
            ead.subjects.each do |subject|
              json = subject['_resolved']
              text = json['terms'].map { |term| term['term'] }.join('--')
              xml.subject text
            end
            
            
            ead.linked_agents.each do |link|

              role = link['role']
              agent = link['_resolved']

              agent['names'].each do |name|
                case agent['agent_type']
                when 'agent_person'
                  xml.persname ['primary_name', 'rest_of_name'].map {|np| name[np] if name[np] }.join(', ')

                when 'agent_family'
                  xml.famname name['family_name']

                when 'agent_corporate_entity'
                  xml.corpname name['primary_name']
                end
              end
            end 
              
          }
          
          xml.dsc {
           
            ead.children.each do |child|
              serialize_child(child, xml)
            end
              
            
          } 
        }
      }
    
    end
    
    builder.to_xml
  end

  
  def serialize_child(child, xml)
    
    xml.c('level' => child.level) {
      
      xml.did {
        xml.unittitle child.title
        
        dates_as_unitdates(child, xml)
        
      }
      
      child.children.each do |kind|
        serialize_child(kind, xml)
      end
      
    }
  end
  
  def dates_as_unitdates(obj, xml)
    
    obj.dates.each do |date|
      d = date['expression']
      xml.unitdate d
    end
  end

end
