class Agent < Sequel::Model(:agents)
  include ASModel
  plugin :validation_helpers

  one_to_many :name_forms

  def self.set_agent_type(json, opts)
    opts["agent_type_id"] = nil

    if json.agent_type
      opts["agent_type_id"] = JSONModel::parse_reference(json.agent_type, opts)[:id]
    end
  end

  def self.apply_name_forms(agent, json, opts)

    opts["agent_id"] = agent.id

    puts
    puts "in Agent.apply_name_forms with:"
    puts "agent: #{agent.inspect}"
    puts "json: #{json}"
    puts "opts: #{opts}"
    puts
    puts "AT model: " + AgentType[agent.agent_type_id].model_name
    puts

    agent.remove_all_name_forms

    name_forms = (json.name_forms or []).map do |nf_or_uri|
      if nf_or_uri.kind_of? String
        # A URI
        JSONModel(:name_form).id_for(nf_or_uri)
      else
        nf = JSONModel(:name_form).from_hash(nf_or_uri)
        eval "#{AgentType[agent.agent_type_id].model_name}.create_from_json(nf, opts).id"
#        NameForm.create_from_json(nf, opts).id
#        NameForm.ensure_exists(nf)
      end
    end

    name_forms.each do |nf_id|
      agent.add_name_form(eval "#{AgentType[agent.agent_type_id].model_name}[nf_id]")
#      agent.add_name_form(NameForm[nf_id])
    end
  end


  def self.create_from_json(json, opts = {})
    set_agent_type(json, opts)
    obj = super(json, opts)
    apply_name_forms(obj, json, opts)
    obj
  end

  def update_from_json(json, opts = {})
    self.class.set_agent_type(json, opts)
    super(json, opts)
  end


  def self.sequel_to_jsonmodel(obj, type)
    json = super(obj, type)

    json.agent_type = JSONModel(:agent_type).uri_for(obj.agent_type_id)

    json
  end


end
