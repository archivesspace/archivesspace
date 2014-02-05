require 'nokogiri'

ASpaceExport::serializer :eac do
  
  def serialize(eac, opts = {})

    builder = Nokogiri::XML::Builder.new do |xml|
      _eac(eac, xml)     
    end
    
    builder.to_xml   
  end
  
  private
  
  def _eac(json, xml)  
    xml.send("eac-cpf", {'xmlns' => 'urn:isbn:1-931666-33-4',
               "xmlns:html" => "http://www.w3.org/1999/xhtml",
               "xmlns:xlink" => "http://www.w3.org/1999/xlink",
               "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
               "xsi:schemaLocation" => "urn:isbn:1-931666-33-4 http://eac.staatsbibliothek-berlin.de/schema/cpf.xsd",
               "xml:lang" => "eng"}) {
      _control(json, xml)
      _cpfdesc(json, xml)
    }
  end
  
  def _control(json, xml)
    xml.control {
      xml.recordId "#{json.uri.gsub(/\//, ':')}"
      
      xml.maintenanceStatus json.create_time == json.system_mtime ? "new" : "revised"
    
      xml.maintenanceAgency {
        xml.agencyName "unknown"
      }
    
      xml.maintenanceHistory {

        json.events.each do |event|
        
          xml.maintenanceEvent {
            xml.eventType event.type
            xml.eventDateTime(:standardDateTime => event.date_time) {
              xml.text event.date_time
            } 
            event.agents.each do |agent|
              xml.agentType agent[0]
              xml.agent agent[1]
            end
          }
        end
          
        # xml.maintenanceEvent {
        #   xml.eventType "created"
        #   ctime = Time.mktime(json.create_time.to_s).utc.strftime '%Y-%m-%dT%H:%M:%S'
        #   xml.eventDateTime(:standardDateTime => ctime) {
        #     xml.text ctime
        #   } 
        #   xml.agentType "human"
        #   xml.agent "unknown"
        # }
        
        # xml.maintenanceEvent {
        #   xml.eventType "revised"
        #   ctime = Time.mktime(json.system_mtime.to_s).utc.strftime '%Y-%m-%dT%H:%M:%S'
        #   xml.eventDateTime(:standardDateTime => ctime) {
        #     xml.text ctime
        #   } 
        #   xml.agentType "human"
        #   xml.agent "unknown"
        # }
      }
    
      json.external_ids.each do |e|
        local_source = e['source'] ? {:localType => e['source']} : nil
        xml.otherRecordId(local_source) {
          xml.text e['external_id']
        }
      end
    
    } 
        
  end
  
  def _cpfdesc(json, xml)
    xml.cpfDescription {
      
      xml.identity {
        
        entity_type = json.jsonmodel_type.sub(/^agent_/, "").sub('corporate_entity', 'corporateBody')
        
        xml.entityType entity_type

        if json.names.length > 1
          xml.nameEntryParallel {
            _build_name_entries(json, xml)
          }
        elsif json.names
          _build_name_entries(json, xml)
        end
      }

      xml.description {
        json.notes.reject {|n| n['jsonmodel_type'] != 'note_bioghist'}.each do |n|
          xml.biogHist {
            n['content'].each do |c|
              # xml.__send__ :insert, c   # << use this method if the note contents are ever valid EAC <description> content
              xml.p c
            end
          }
        end
      }
      
    }
  end


  def _build_name_entries(json, xml)
    json.names.each do |name|
      xml.nameEntry {
        xml.authorizedForm name['rules'] if name['rules']
        xml.authorizedForm name['source'] if name['source']

        json.name_part_fields.each do |field, localType|
          localType = localType.nil? ? field : localType
          next unless name[field]
          xml.part(:localType => localType) {
            xml.text name[field]
          }
        end

        name['use_dates'].each do |date|
          xml.useDates {
            xml.dateRange date['expression']
            xml.dateRange date['expression']
            case date['date_type']
            when 'bulk', 'inclusive'
              xml.dateRange {
                xml.fromDate(:standardDate => date['begin']) {
                  xml.text date['begin']
                }
                xml.toDate(:standardDate => date['end']) {
                  xml.text date['end']
                }
              }
            when 'single'
              xml.dateRange {
                xml.date(:standardDate => date['begin']) {
                  xml.text date['begin']
                }
              }
            end
          }
        end
      }
    end
  end
end
