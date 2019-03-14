module SlugHelpers
  # auto generate a slug for this instance based on id
  # if for any reason we can't generate an id slug, then turn autogenerate off for this entity.
  def self.generate_slug_by_id!(entity)

    slug = id_based_slug_for(entity, entity.class)

    entity[:slug] = slug

    if slug.empty? || slug.nil?

      entity[:is_slug_auto] = 0
    end
  end

  # generate and return a string for a slug based on this thing's ID.
  # unlike #generate_slug_by_id!, this method does not modify the passed in object.
  def self.id_based_slug_for(entity, klass)

    if klass == Resource || klass == Accession
      if AppConfig[:generate_resource_slugs_with_eadid] && entity[:ead_id] && klass == Resource

        # use EADID if configured. Otherwise, use identifier.
        slug = entity[:ead_id]
      else
        if entity.respond_to?(:format_multipart_identifier)
          slug = entity.format_multipart_identifier
        else
          slug = "#{entity[:id_0]}"
          slug += "-#{entity[:id_1]}" if entity[:id_1]
          slug += "-#{entity[:id_2]}" if entity[:id_2]
          slug += "-#{entity[:id_3]}" if entity[:id_3]
        end
      end

    elsif klass == Classification || klass == ClassificationTerm
      slug = entity[:identifier]

    elsif klass == DigitalObject
      slug = entity[:digital_object_id]

    elsif klass == Repository
      slug = entity[:repo_code]

    elsif klass == ArchivalObject
      if AppConfig[:generate_archival_object_slugs_with_cuid]
        slug = entity[:component_id]
      else
        slug = entity[:ref_id]
      end

    elsif klass == DigitalObjectComponent
      slug = entity[:component_id]

    elsif klass == Subject
      slug = entity[:authority_id]

     #turned autogen on without updating any other data
     #should be JSON only
    elsif is_agent_type?(klass)

      if entity.class.to_s =~ /JSONModel/
        primary_name = entity["names"].select {|n| n["is_display_name"] == true }


        # we should have a single primary name. 
        # if we don't, then someentity's wrong and use the first name as a fallback.
        if primary_name.length == 1
          primary_name = primary_name[0]
        else
          primary_name = entity["names"][0]
        end

        slug = primary_name["authority_id"]
      elsif is_agent_type?(entity.class)
        disp_name = get_json_for_agent(entity, klass)

        #AgentPerson.to_jsonmodel(entity).display_name

        slug = disp_name["authority_id"]
      end

    else
      slug = ""
    end

    return clean_slug(slug, klass)
  end

  private

  # In certain cases (like turning on auto slug for an agent)
  # we'll want to get all the name and authority data without doing a bunch of DB queries.
  def self.get_json_for_agent(agent_record, klass)


    klass.to_jsonmodel(agent_record).display_name
  end

end