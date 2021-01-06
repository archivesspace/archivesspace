module AgentNameDates
	# ANW-429: This code runs when a single or ranged date is updated.
  # If the date is attached to a date of existence for an agent, that agent's display name is pulled and updated with data from this date, if there is no name use date for the display name.
  # It would be really nice to do this at the JSONModel layer instead of with Sequel calls like here below... But I couldn't figure out a way to do that.
  # As far as I can tell, there isn't a way to get the ID of the parent date label object from the AutoGenerator in the Name classes.
  # Also tried getting this data from a after_save/update hook in the parent label class, but these date subrecords were not accessible -- it looks like they weren't created yet from the context of inside that hook.

  def update_associated_name_forms
    sdl = StructuredDateLabel.first(:id => self.structured_date_label_id)

    # See if label object is attached directly to an agent, which indicates a date of existence
    if sdl.agent_person_id
      agent_id = sdl.agent_person_id
      agent_json = AgentPerson.to_jsonmodel(agent_id)
      agent_name = NamePerson.first(:agent_person_id => agent_id, :is_display_name => 1) 
      name_json = NamePerson.to_jsonmodel(agent_name.id)

    elsif sdl.agent_family_id
      agent_id = sdl.agent_family_id
      agent_json = AgentFamily.to_jsonmodel(agent_id)
      agent_name = NameFamily.first(:agent_family_id => agent_id, :is_display_name => 1) 
      name_json = NameFamily.to_jsonmodel(agent_name.id)

    elsif sdl.agent_corporate_entity_id
      agent_id = sdl.agent_corporate_entity_id
      agent_json = AgentCorporateEntity.to_jsonmodel(agent_id)
      agent_name = NameCorporateEntity.first(:agent_corporate_entity_id => agent_id, :is_display_name => 1) 
      name_json = NameCorporateEntity.to_jsonmodel(agent_name.id)

    elsif sdl.agent_software_id
      agent_id = sdl.agent_software_id
      agent_json = AgentSoftware.to_jsonmodel(agent_id)
      agent_name = NameSoftware.first(:agent_software_id => agent_id, :is_display_name => 1) 
      name_json = NameSoftware.to_jsonmodel(agent_name.id)
    end

    # This code runs if we find an agent display name directly attached to this date subrecord with no dates of it's own -- name dates take precedence over dates of existence.
    # We'll then generate the string for the display name from the dates of existence, and update it. 
    if name_json && name_json['use_dates'].length == 0 && agent_json['dates_of_existence'].length > 0
      # as per the spec, we'll only concern ourselves with the first date defined.
      doe_json = agent_json["dates_of_existence"][0]

      name_json['sort_name_date_string'] = stringify_date(doe_json)

      agent_name.update_from_json(name_json)
    end
  end

  # input is an array of JSONModel date objects corresponding to the dates of existence for the parent agent
  # output is a string form of date object for use in sort name string

  # processing in pseudocode
  # if date expression
  #   return date expression
  # else if begin and end date
  #   return begin date year - end date year
  # else
  #   return begin date year
  def stringify_date(date_json)
    date_substring = ""

    if date_json["date_type_structured"] == "single"
      std = date_json["structured_date_single"]['date_standardized']
      exp = date_json["structured_date_single"]['date_expression']

      # only grab the year
      std = std.split("-")[0] unless std.nil?

      if exp 
        date_substring = exp
      elsif std 
        s_type = date_json["structured_date_single"]["date_standardized_type"]
        date_substring = std
        date_substring << " #{I18n.t('enumerations.date_standardized_type.' + s_type)}" unless s_type == "standard"
      end
    elsif date_json["date_type_structured"] == "range"
      b_std = date_json["structured_date_range"]['begin_date_standardized']
      b_exp = date_json["structured_date_range"]['begin_date_expression']
      e_std = date_json["structured_date_range"]['end_date_standardized']
      e_exp = date_json["structured_date_range"]['end_date_expression']

      b_s_type = date_json["structured_date_range"]["begin_date_standardized_type"]
      e_s_type = date_json["structured_date_range"]["end_date_standardized_type"]

      # only grab the years
      b_std = b_std.split("-")[0] unless b_std.nil?
      e_std = e_std.split("-")[0] unless e_std.nil?

      if b_exp && e_exp
        date_substring = b_exp + "-" + e_exp
      elsif b_exp
        date_substring = b_exp
      elsif b_std && e_std
        b_std += " #{I18n.t('enumerations.date_standardized_type.' + b_s_type)}" unless b_s_type == "standard"
        e_std += " #{I18n.t('enumerations.date_standardized_type.' + e_s_type)}" unless e_s_type == "standard"
        date_substring = b_std + "-" + e_std
      elsif b_std
        b_std += " #{I18n.t('enumerations.date_standardized_type.' + b_s_type)}" unless b_s_type == "standard"
        date_substring = b_std
      end
    end

    return date_substring
  end
end