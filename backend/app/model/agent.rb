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


  def one_to_many_relationship(opts)
    one_to_many opts[:table], :class => opts[:class]

    alias_method opts[:plural_type], opts[:table]
    alias_method :"remove_all_#{opts[:plural_type]}", :"remove_all_#{opts[:table]}"
    alias_method :"add_#{opts[:type]}", :"add_#{opts[:table]}"
  end

end
