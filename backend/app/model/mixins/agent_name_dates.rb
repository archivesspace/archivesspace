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
      processor = SortNameProcessor::Person

    elsif sdl.agent_family_id
      agent_id = sdl.agent_family_id
      agent_json = AgentFamily.to_jsonmodel(agent_id)
      agent_name = NameFamily.first(:agent_family_id => agent_id, :is_display_name => 1) 
      name_json = NameFamily.to_jsonmodel(agent_name.id)
      processor = SortNameProcessor::Family

    elsif sdl.agent_corporate_entity_id
      agent_id = sdl.agent_corporate_entity_id
      agent_json = AgentCorporateEntity.to_jsonmodel(agent_id)
      agent_name = NameCorporateEntity.first(:agent_corporate_entity_id => agent_id, :is_display_name => 1) 
      name_json = NameCorporateEntity.to_jsonmodel(agent_name.id)
      processor = SortNameProcessor::CorporateEntity

    elsif sdl.agent_software_id
      agent_id = sdl.agent_software_id
      agent_json = AgentSoftware.to_jsonmodel(agent_id)
      agent_name = NameSoftware.first(:agent_software_id => agent_id, :is_display_name => 1) 
      name_json = NameSoftware.to_jsonmodel(agent_name.id)
      processor = SortNameProcessor::Software
    end

    # This code runs if we find an agent display name directly attached to this date subrecord with no dates of it's own -- name dates take precedence over dates of existence.
    # We'll then generate the string for the display name from the dates of existence, and update it. 
    if name_json && name_json['dates'].nil? && agent_json['dates_of_existence'].length > 0 && agent_name.sort_name_auto_generate == 1
      extras = { 'dates_of_existence' => agent_json["dates_of_existence"] }
      agent_name.update(sort_name: processor.process(name_json, extras), system_mtime: Time.now)
    end
  end
end