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


  def one_to_many_names(opts)
    one_to_many opts[:table], :class => opts[:class]

    alias_method :names, opts[:table]
    alias_method :remove_all_names, :"remove_all_#{opts[:table]}"
    alias_method :add_name, :"add_#{opts[:table]}"
  end



end
