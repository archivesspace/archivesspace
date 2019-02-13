module SlugHelpers

 # auto generate a slug for this instance based on name
  # if for any reason we can't generate an id slug, then turn autogenerate off for this entity.
  def self.generate_slug_by_name!(entity)
    debug("called with params", "entity: #{entity.inspect}")

    slug = name_based_slug_for(entity, entity.class)


    if is_agent_name_type?(entity.class)
      debug("agent name type found")

      # prevent slug from getting nulled out on create
      # TODO: find a way to remove this check
      unless slug.nil? || slug.empty?
      
        update_agent_slug_from_name(entity, slug)
      end

    elsif slug.nil? || slug.empty? 
      debug("empty slug generated")

      if entity.slug.nil? || entity.slug.empty?
        debug("turning off is_slug_auto for #{entity.class}")
        entity[:is_slug_auto] = 0 
      end
    else
      debug("setting slug value for #{entity.class}")
      entity[:slug] = slug
    end
  end


  # Generate and return a string for a slug based on this thing's title or name.
  # unlike #generate_slug_by_name!, this method does not modify the passed in object.
  # NOTE: 'klass' is passed in by the caller to give us a clue as to what kind of entity we're working with.
  # 'entity' is a data structure that has what we need. It may be a JSONModel or a Sequel object.

  def self.name_based_slug_for(entity, klass)
    debug("called with params", "entity: #{entity.inspect} klass: #{klass.to_s}")

    if !entity[:title].nil? && !entity[:title].empty? &&
       !is_agent_name_type?(klass)
      debug "entity has a title"

      slug = entity[:title]

    elsif !entity[:name].nil? && !entity[:name].empty? &&
          !is_agent_name_type?(klass)
      debug "entity has a name"

      slug = entity[:name]

    # This codepath is run on updating slugs for agents, where we get either a Sequel Name object, or a Hash
    elsif is_agent_name_type?(klass)
      if entity.class == Hash
        debug "entity is a NameAgent Hash"

        # turn keys into symbols, that's what we expect down the line
        entity.keys.each do |key|
          entity[(key.to_sym rescue key) || key] = entity.delete(key)
        end

        slug = get_agent_name_string_from_hash(entity, klass)

      elsif is_agent_name_type?(entity.class)
        debug "entity is a NameAgent Sequel object"

        slug = get_agent_name_string_from_sequel(entity, klass)
      end

    else
      debug "entity is not recognized"

      slug = ""
    end
    
    debug("generated slug", "slug: #{slug}")

    return clean_slug(slug, klass)
  end

  private

  # takes in a hash like object representing a name record for an agent.
  # returns the expected slug given the name fields
  def self.get_agent_name_string_from_hash(hash, klass)
    debug("called with params", "hash: #{hash.inspect} klass: #{klass.to_s}")

    result = ""

    agent_class = get_agent_class_for_name_class(klass)

    case agent_class
    when "AgentPerson"
      if hash[:name_order] === "inverted"
        result << hash[:primary_name] if hash[:primary_name]
        result << ", #{hash[:rest_of_name]}" if hash[:rest_of_name]

      elsif hash[:name_order] === "direct"
        result << hash[:rest_of_name] if hash[:rest_of_name]
        result << " #{hash[:primary_name]}" if hash[:primary_name]
      else
        result << hash[:primary_name]
      end
    when "AgentFamily"
      result = hash[:family_name] if hash[:family_name]
    when "AgentCorporateEntity"
      result << "#{hash[:primary_name]}" if hash[:primary_name]
      result << ". #{hash[:subordinate_name_1]}" if hash[:subordinate_name_1]
      result << ". #{hash[:subordinate_name_2]}" if hash[:subordinate_name_2]
    when "AgentSoftware"
      result = hash[:software_name] if hash[:software_name]
    end

    debug("return value", result.to_s)

    result
  end

  # Takes a NameAgent record (eg., NamePerson) and turns it into a hash so we can generate the right slug given the name fields
  def self.get_agent_name_string_from_sequel(name_record, klass)
    debug("called with params", "name_record: #{name_record.inspect} klass: #{klass.to_s}")

    name_values_hash = name_record.values

    # resolve name_order_id into it's string value
    name_values_hash[:name_order] = EnumerationValue[name_record[:name_order_id]][:value] rescue nil

    puts "name_values_hash: #{name_values_hash.inspect}"

    return get_agent_name_string_from_hash(name_values_hash, klass)
  end

  def self.get_agent_class_for_name_class(klass)
    debug("called with params", "klass: #{klass.to_s}")

    case klass.to_s
    when "NamePerson"
      "AgentPerson"
    when "NameCorporateEntity"
      "AgentCorporateEntity"
    when "NameFamily"
      "AgentFamily"
    when "NameSoftware"
      "AgentSoftware"
    end
  end 

  # Generating a slug for an agent is done through the name record (e.g., NamePerson)
  # This method updates the agent associated with the name record that the slug was generated from.
  def self.update_agent_slug_from_name(entity, slug)
    debug("called with params", "entity: #{entity.inspect} slug: #{slug.to_s}")

    agent = nil

    case entity.class.to_s
    when "NamePerson"
      agent = AgentPerson[entity[:agent_person_id]]
    when "NameFamily"
      agent = AgentFamily[entity[:agent_family_id]]
    when "NameCorporateEntity"
      agent = AgentCorporateEntity[entity[:agent_corporate_entity_id]]
    when "NameSoftware"
      agent = AgentSoftware[entity[:agent_software_id]]
    end

    debug("agent found", "#{agent.inspect}") if agent

    if agent && is_slug_auto_enabled?(agent)
      debug "updating agent record", "slug: #{slug}"
      agent.update(:slug => slug)
    end
  end

end