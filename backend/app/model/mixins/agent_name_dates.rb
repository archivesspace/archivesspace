module AgentNameDates
	# ANW-429: This code runs when a single or ranged date is updated.
  # If the date is attached to a date of existence for an agent, that agent's display name is pulled and updated with data from this date.
  # It would be really nice to do this at the JSONModel layer instead of with Sequel calls like here below... But I couldn't figure out a way to do that.
  # As far as I can tell, there isn't a way to get the ID of the parent date label object from the AutoGenerator in the Name classes.
  # Also tried getting this data from a after_save/update hook in the parent label class, but these date subrecords were not accessible -- it looks like they weren't created yet from the context of inside that hook.
  # TODO: There are some places where JSONModel calls are used. Maybe this is unnecessary -- I wanted to rely on Sequel as little as possible so it's only used for queries, not updates.

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

    # This code runs if we find an agent display name directly attached to this date subrecord. We'll then generate the string for the name, and update it. 
    if name_json
      doe_json = agent_json["dates_of_existence"]

      name_json['sort_name_date_string'] = stringify_structured_dates_for_sort_name(doe_json)

      agent_name.update_from_json(name_json)
    end
  end

  # iterate through all dates of existence to generate a string version for inclusion in name.sort_name
  # input is an array of JSONModel date objects corresponding to the dates of existence for the parent agent
  def stringify_structured_dates_for_sort_name(doe_json)
    date_substrings = []

    doe_json.each do |doe|
      date_substring = ""

      if doe["date_type_enum"] == "single"
        std = doe["structured_date_single"]['date_standardized']
        exp = doe["structured_date_single"]['date_expression']

        std = std.split("-")[0] unless std.nil?

        # either the standardized date or expression should have some content
        if std
          date_substring = std
        elsif exp
          date_substring = exp
        end
      elsif doe["date_type_enum"] == "range"
        b_std = doe["structured_date_range"]['begin_date_standardized']
        b_exp = doe["structured_date_range"]['begin_date_expression']
        e_std = doe["structured_date_range"]['end_date_standardized']
        e_exp = doe["structured_date_range"]['end_date_expression']

        b_std = b_std.split("-")[0] unless b_std.nil?
        e_std = e_std.split("-")[0] unless e_std.nil?

        if b_std && e_std
          date_substring = b_std + "-" + e_std
        elsif b_exp && e_exp
          date_substring = b_exp + "-" + e_exp
        end
      end

      date_substrings.push(date_substring)
    end

    return date_substrings.join(", ")
  end
end