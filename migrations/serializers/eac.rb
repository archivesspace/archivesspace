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
    xml.send("eac-cpf", 'xmlns' => 'urn:isbn:1-931666-33-4') {
      _control(json, xml)
      _cpfdesc(json, xml)
    }
  end
  
  def _control(json, xml)
    xml.control {
      xml.recordId "#{json.uri.gsub(/\//, ':')}"
      
      xml.maintenanceStatus json.create_time == json.last_modified ? "new" : "revised"
    
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
        #   ctime = Time.mktime(json.last_modified.to_s).utc.strftime '%Y-%m-%dT%H:%M:%S'
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

        # TODO: It might be nice to flag these attributes on the schema 
        # so they can be pulled out automatically
        json.names.each do |n|
          xml.nameEntry {
            case json.jsonmodel_type
            when 'agent_person'
              _name_parts(n, xml, ["primary_name", "title", "prefix", "rest_of_name", "suffix", "fuller_form", "number"])
            when 'agent_family'
              _name_parts(n, xml, ["family_name", "prefix"])
            when 'agent_software'
              _name_parts(n, xml, ["software_name", "version", "manufacturer"])
            when 'agent_corporate_entity'
              _name_parts(n, xml, ["primary_name", "subordinate_name_1", "subordinate_name_2", "number"])
            end   
          }
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
  
  def _name_parts(name, xml, types)
    types << 'sort_name'
    types.each do |t|
      next unless name[t]
      xml.part(:localType => t) {
        xml.text name[t]
      }
    end
  end

end
