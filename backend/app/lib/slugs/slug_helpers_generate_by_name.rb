module SlugHelpers

  # auto generate a slug for the Agent associated with this AgentName
  # Then, find that associated Agent and update it's slug.
  # if for any reason we generate an empty slug, then turn autogen off for the agent.
  def self.generate_slug_for_agent_name!(entity)
    slug = name_based_slug_for(entity, entity.class)
    update_agent_slug_from_name(entity, slug)
  end


  # Generate and return a string for a slug based on this thing's title or name.
  # unlike #generate_slug_by_name!, this method does not modify the passed in object.
  # NOTE: 'klass' is passed in by the caller to give us a clue as to what kind of entity we're working with.
  # 'entity' is a data structure that has what we need. It may be a JSONModel or a Sequel object.

  def self.name_based_slug_for(entity, klass)
    if klass == Repository
      # Always use repo_code for repository slug
      slug = entity[:repo_code]
    elsif !is_agent_name_type?(klass)
      if !entity[:title].nil? && !entity[:title].empty?
        slug = entity[:title]
      elsif !entity[:name].nil? && !entity[:name].empty?
        slug = entity[:name]
      end
    # This codepath is run on updating slugs for agents, where we get either a Sequel Name object, or a Hash
    elsif is_agent_name_type?(klass)
      if entity.class == Hash
        # turn keys into symbols, that's what we expect down the line
        entity.keys.each do |key|
          entity[(key.to_sym rescue key) || key] = entity.delete(key)
        end
        slug = get_agent_name_string_from_hash(entity, klass)
      elsif is_agent_name_type?(entity.class)
        slug = get_agent_name_string_from_sequel(entity, klass)
      end
    else
      slug = ""
    end

    slug = clean_slug(slug)

    # only de-dupe and update if our base slug has changed from it's previous value
    previous_slug = entity[:slug]
    if base_slug_changed?(slug, previous_slug)
      return run_dedupe_slug(slug)
    else
      return previous_slug
    end
  end

  private

  # takes in a hash like object representing a name record for an agent.
  # returns the expected slug given the name fields
  def self.get_agent_name_string_from_hash(hash, klass)
    result = ""

    agent_class = get_agent_class_for_name_class(klass)

    case agent_class
    when "AgentPerson"
      if hash[:name_order] === "inverted"
        result << hash[:primary_name] if hash[:primary_name]
        result << "_" + hash[:rest_of_name] if hash[:rest_of_name]
      elsif hash[:name_order] === "direct"
        result << hash[:rest_of_name] if hash[:rest_of_name]
        result << "_" + hash[:primary_name] if hash[:primary_name]
      else
        result << hash[:primary_name]
      end
    when "AgentFamily"
      result = hash[:family_name] if hash[:family_name]
    when "AgentCorporateEntity"
      result << hash[:primary_name] if hash[:primary_name]
      result << "_" + hash[:subordinate_name_1] if hash[:subordinate_name_1]
      result << "_" + hash[:subordinate_name_2] if hash[:subordinate_name_2]
    when "AgentSoftware"
      result = hash[:software_name] if hash[:software_name]
    end

    result
  end

  # Takes a NameAgent record (eg., NamePerson) and turns it into a hash so we can generate the right slug given the name fields
  def self.get_agent_name_string_from_sequel(name_record, klass)
    name_values_hash = name_record.values

    # resolve name_order_id into it's string value
    name_values_hash[:name_order] = EnumerationValue[name_record[:name_order_id]][:value] rescue nil
    return get_agent_name_string_from_hash(name_values_hash, klass)
  end

  def self.get_agent_class_for_name_class(klass)
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

    if agent && is_slug_auto_enabled?(agent)
      agent.update(:slug => slug)

      agent.update(:is_slug_auto => 0) if slug.empty?
    end
  end

end
