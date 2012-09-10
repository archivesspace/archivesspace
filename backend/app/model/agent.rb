module Agent


  def link_names(agent, json, name_model, json_model, opts = {})
    agent.remove_all_names

    (json.names or []).each do |name_or_uri|
      obj = nil

      if name_or_uri.kind_of? String
        # A URI
        obj = name_model[json_model.id_for(name_or_uri)]
      else
        hash = json_model.from_hash(name_or_uri)
        obj = name_model.create_from_json(hash, opts)
      end

      agent.add_name(obj)
    end
  end


  def apply_contact_details(agent, json, contact_model, json_model, opts = {})
    agent.remove_all_contact_details

    (json.contact_details or []).each do |contact_or_url|
      obj = nil

      if contact_or_url.kind_of? String
        # A URI
        obj = contact_model[json_model.id_for(contact_or_url)]
      else
        hash = json_model.from_hash(contact_or_url)
        obj = contact_model.create_from_json(hash, opts)
      end

      agent.add_contact_details(obj)
    end
  end


  def one_to_many_names(opts)
    one_to_many opts[:table], :class => opts[:class]

    alias_method :names, opts[:table]
    alias_method :remove_all_names, :"remove_all_#{opts[:table]}"
    alias_method :add_name, :"add_#{opts[:table]}"
  end


  def one_to_many_contact_details
    one_to_many :agent_contact

    alias_method :contact_details, :agent_contact
    alias_method :remove_all_contact_details, :"remove_all_agent_contact"
    alias_method :add_contact_details, :add_agent_contact
  end

end
