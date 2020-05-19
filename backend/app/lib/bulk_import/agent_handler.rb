require_relative "handler"

require_relative "../../model/agent_person"
require_relative "../../model/agent_family"
require_relative "../../model/agent_corporate_entity"
require_relative "bulk_import_mixins"

class AgentHandler < Handler
  AGENT_TYPES = { "families" => "family", "family" => "family", "corporate_entities" => "corporate_entity", "corporate_entity" => "corporate_entity", "people" => "person", "person" => "person" }

  def initialize(current_user)
    @agents = {}
    @agent_role ||= CvList.new("linked_agent_role", current_user)
    @agent_relators ||= CvList.new("linked_agent_archival_record_relators", current_user)
  end

  def renew
    clear(@agent_relators)
    clear(@agent_role)
    @agents = {}
  end

  def key_for(agent)
    key = "#{agent[:type]}_#{agent[:name]}"
    key
  end

  def build(type, id, header, relator, role)
    role = "creator" if role.nil?
    {
      :type => AGENT_TYPES[type],
      :id => id,
      :name => header || (id ? I18n.t("bulk_import.unfound_id", :id => id, :type => "Agent") : nil),
      :role => role,
      :relator => relator,
      :id_but_no_name => id && !header,
    }
  end

  def get_agent_header(type, agent_obj)
    if type == "family"
      header = agent_obj.names[0]["family_name"]
    else
      header = agent_obj.names[0]["primary_name"]
    end
    header
  end

  def get_by_id(type, id)
    agent_obj = nil
    model = get_model(type)
    begin
      agent_obj = model.get_or_die(Integer(id))
      objs = model.sequel_to_jsonmodel([agent_obj])
      agent_obj = objs[0]
    rescue Exception => e
      if !e.message.end_with?(" not found")
        raise BulkImportException.new(I18n.t("bulk_import.error.no_create", :why => e.message))
      end
    end
    agent_obj
  end

  def get_or_create(type, id, header, relator, role, report)
    agent = build(type, id, header, relator, role)
    agent_key = key_for(agent)
    if !(agent_obj = stored(@agents, "#{agent[:type]}_#{agent[:id]}", agent_key))
      unless agent[:id].nil?
        agent_obj = get_by_id(type, agent[:id])
      end
      begin
        if !agent_obj
          begin
            agent_obj = get_db_agent(agent, report)
          rescue Exception => e
            if e.message == "More than one match found in the database"
              disam = agent[:name] + DISAMB_STR
              report.add_info(I18n.t("bulk_import.warn.disam", :which => agent[:name], :name => disam))
              agent[:name] = disam
            else
              raise e
            end
          end
        end
        if !agent_obj
          agent_obj = create_agent(agent)
          report.add_info(I18n.t("bulk_import.created", :what => "#{I18n.t("bulk_import.agent")}[#{agent[:name]}]", :id => agent_obj.uri))
        end
      rescue Exception => e
        raise BulkImportException.new(I18n.t("bulk_import.error.no_create", :why => e.message))
      end
    end
    agent_link = nil
    if agent_obj
      if agent[:id_but_no_name]
        agent_key = "#{agent[:type]}_#{get_agent_header(type, agent_obj)}"
        agent[:id_but_no_name] = nil
      end
      id = "#{agent[:type]}_#{agent[:id]}"
      @agents[id] = agent_obj
      @agents[agent_key] = agent_obj
      agent_link = { "ref" => agent_obj.uri }
      begin
        agent_link["role"] = @agent_role.value(agent[:role])
      rescue Exception => e
        if e.message.start_with?("NOT FOUND")
          raise BulkImportException.new(I18n.t("bulk_import.error.bad_role", :label => agent[:role]))
        else
          raise BulkImportException.new(I18n.t("bulk_import.error.role_invalid", :label => agent[:role], :why => e.message))
        end
      end
      begin
        agent_link["relator"] = @agent_relators.value(agent[:relator]) if !agent[:relator].nil?
      rescue Exception => e
        if e.message.start_with?("NOT FOUND")
          raise BulkImportException.new(I18n.t("bulk_import.error.bad_relator", :label => agent[:relator]))
        else
          raise BulkImportException.new(I18n.t("bulk_import.error.relator_invalid", :label => agent[:relator], :why => e.message))
        end
      end
    end
    agent_link
  end

  def create_agent(agent)
    begin
      ret_agent = JSONModel("agent_#{agent[:type]}".to_sym).new._always_valid!
      ret_agent.names = [name_obj(agent)]
      ret_agent.publish = !(agent[:id_but_no_name] || agent[:name].end_with?(DISAMB_STR))
      model = get_model(agent[:type])
      ret_agent = save(ret_agent, model)
    rescue Exception => e
      raise Exception.new(I18n.t("bulk_import.error.no_create", :why => e.message))
    end
    ret_agent
  end

  def get_db_agent(agent, report)
    ret_ag = nil
    if agent[:id]
      ret_ag = get_by_id(agent[:type], agent[:id])
    end
    if !ret_ag
      a_params = { :q => "title:\"#{agent[:name]}\" AND primary_type:agent_#{agent[:type]}" }
      ret_ag = search(nil, a_params, "agent_#{agent[:type]}".to_sym, "", "title:#{agent[:name]}")
    end
    ret_ag
  end

  def get_model(type)
    model = nil
    case AGENT_TYPES[type]
    when "person"
      model = AgentPerson
    when "family"
      model = AgentFamily
    when "corporate_entity"
      model = AgentCorporateEntity
    end
    model
  end

  def name_obj(agent)
    obj = JSONModel("name_#{agent[:type]}".to_sym).new._always_valid!
    obj.source = "ingest"
    obj.authorized = true
    obj.is_display_name = true
    if agent[:type] == "family"
      obj.family_name = agent[:name]
    else
      obj.primary_name = agent[:name]
      obj.name_order = "direct" if agent[:type] == "person"
    end
    obj
  end
end # agent
