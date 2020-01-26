require_relative 'handler'
class AgentHandler < Handler
    @@agents = {} 
    @@agent_role ||= CvList.new('linked_agent_role')
    @@agent_relators ||= CvList.new('linked_agent_archival_record_relators')
    AGENT_TYPES = { 'families' => 'family', 'corporate_entities' => 'corporate_entity', 'people' => 'person'}
    def self.renew
      clear(@@agent_relators)
      clear(@@agent_role)
      @@agents = {}
    end
    def self.key_for(agent)
      key = "#{agent[:type]} #{agent[:name]}"
      key
    end
    
   def self.build(row, type, num)
     id = row.fetch("#{type}_agent_record_id_#{num}", nil)
     input_name = row.fetch("#{type}_agent_header_#{num}",nil)
     role = row.fetch("#{type}_agent_role_#{num}", nil)
     role ='creator' if role.blank?
     {
       :type => AGENT_TYPES[type],
       :id => id,
       :name => input_name || (id ? I18n.t('plugins.aspace-import-excel.unfound_id', :id => id, :type => 'Agent') : nil),
       :role => role,
       :relator => row.fetch("#{type}_agent_relator_#{num}", nil) ,
       :id_but_no_name => id && !input_name
     }
   end

   def self.get_or_create(row, type, num, resource_uri, report)
     agent = build(row, type, num)
     agent_key = key_for(agent)
     if !(agent_obj = stored(@@agents, agent[:id], agent_key))
       unless agent[:id].blank?
         begin
           agent_obj = JSONModel("agent_#{agent[:type]}".to_sym).find(agent[:id])
         rescue Exception => e
           if e.message != 'RecordNotFound'
             raise ExcelImportException.new( I18n.t('plugins.aspace-import-excel.error.no_agent', :num => num, :why => e.message))
           end
         end
       end
       begin
        if !agent_obj
          begin
            agent_obj = get_db_agent(agent, resource_uri, num)
          rescue Exception => e
            if e.message == 'More than one match found in the database'
              agent[:name] = agent[:name] + DISAMB_STR
              report.add_info(I18n.t('plugins.aspace-import-excel.warn.disam', :name => agent[:name]))
            else
              raise e
            end
          end
        end
        if !agent_obj
          agent_obj = create_agent(agent, num)
          report.add_info(I18n.t('plugins.aspace-import-excel.created', :what =>"#{I18n.t('plugins.aspace-import-excel.agent')}[#{agent[:name]}]", :id => agent_obj.uri))
        end
     rescue Exception => e
       raise ExcelImportException.new( I18n.t('plugins.aspace-import-excel.error.no_agent', :num =>  num,  :why => e.message))
     end
    end
    agent_link = nil
      if agent_obj
        if agent[:id_but_no_name]
         @@agents[agent[:id].to_s] = agent_obj
        else
         @@agents[agent_obj.id.to_s] = agent_obj
        end
        @@agents[agent_key] = agent_obj
        agent_link = {"ref" => agent_obj.uri}
        begin
          agent_link["role"] = @@agent_role.value(agent[:role])
        rescue Exception => e
          if e.message.start_with?("NOT FOUND")
            raise ExcelImportException.new(I18n.t('plugins.aspace-import-excel.error.bad_role', :label => agent[:role]))
          else
            raise ExcelImportException.new(I18n.t('plugins.aspace-import-excel.error.role_invalid', :label => agent[:role], :why => e.message))
        end
      end
      begin
        agent_link["relator"] =  @@agent_relators.value(agent[:relator]) if !agent[:relator].blank?
      rescue Exception => e
        if e.message.start_with?("NOT FOUND")
          raise ExcelImportException.new(I18n.t('plugins.aspace-import-excel.error.bad_relator', :label => agent[:relator]))
        else
          raise ExcelImportException.new(I18n.t('plugins.aspace-import-excel.error.relator_invalid', :label => agent[:relator], :why => e.message))
        end
      end
    end
     agent_link
   end

  def self.create_agent(agent, num)
    begin
      ret_agent = JSONModel("agent_#{agent[:type]}".to_sym).new._always_valid!
      ret_agent.names = [name_obj(agent)]
      ret_agent.publish = !(agent[:id_but_no_name] || agent[:name].ends_with?(DISAMB_STR))
      ret_agent.save
    rescue Exception => e
       raise Exception.new(I18n.t('plugins.aspace-import-excel.error.no_agent', :num => num, :why => e.message))
    end
    ret_agent
  end

  def self.get_db_agent(agent, resource_uri, num)
    ret_ag = nil
    if agent[:id]
      begin
        ret_ag = JSONModel("agent_#{agent[:type]}".to_sym).find(agent[:id])
      rescue Exception => e
        if e.message != 'RecordNotFound' 
          raise ExcelImportException.new( I18n.t('plugins.aspace-import-excel.error.no_agent', :num => num, :why => e.message))
        end
      end
    end
    if !ret_ag
      a_params = {"q" => "title:\"#{agent[:name]}\" AND primary_type:agent_#{agent[:type]}"}
      repo = resource_uri.split('/')[2]
      ret_ag = search(repo, a_params, "agent_#{agent[:type]}".to_sym,'', "title:#{agent[:name]}")
    end
    ret_ag
  end

   def self.name_obj(agent)
     obj = JSONModel("name_#{agent[:type]}".to_sym).new._always_valid!
     obj.source = 'ingest'
     obj.authorized = true
     obj.is_display_name = true
     if agent[:type] == 'family'
       obj.family_name = agent[:name]
     else
       obj.primary_name = agent[:name]
       obj.name_order = 'direct' if agent[:type] == 'person'
     end
     obj
   end
  end # agent

