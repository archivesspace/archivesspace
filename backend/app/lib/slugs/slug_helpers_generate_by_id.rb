module SlugHelpers
  # auto generate a slug for this instance based on id
  # if for any reason we can't generate an id slug, then turn autogenerate off for this entity.
  def self.generate_slug_by_id!(entity)
    debug("called with params", "entity: #{entity.to_s}")

    slug = id_based_slug_for(entity, entity.class)

    if slug.empty? || slug.nil?
      debug("no slug generated" "turning off is_slug_auto for #{entity.inspect}")

      entity[:is_slug_auto] = 0
    else
      debug("updating slug for entity", "entity: #{entity} slug: #{slug}")

      entity[:slug] = slug
    end
  end

  # generate and return a string for a slug based on this thing's ID.
  # unlike #generate_slug_by_id!, this method does not modify the passed in object.
  def self.id_based_slug_for(entity, klass)
    debug("called with params", "entity: #{entity.inspect} klass: #{klass.to_s}")

    if klass == Resource || klass == Accession
      if AppConfig[:generate_resource_slugs_with_eadid] && entity[:ead_id] && klass == Resource
        debug("generating for resource with EADID")

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
      slug = entity[:ref_id]

    elsif klass == DigitalObjectComponent
      slug = entity[:component_id]

    elsif klass == Subject
      slug = entity[:authority_id]

     #turned autogen on without updating any other data
     #should be JSON only
    elsif is_agent_type?(klass)
      debug("generating for agent")

      if entity.class.to_s =~ /JSONModel/
        primary_name = entity["names"].select {|n| n["is_display_name"] == true }

        debug("found JSON agent and primary_name", "primary_name: #{primary_name.inspect}") 

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

        debug("found a Sequel object and display_name", "display_name: #{disp_name.inspect}")
        #AgentPerson.to_jsonmodel(entity).display_name

        slug = disp_name["authority_id"]
      end

    else
      slug = ""
    end

    debug("generated slug", "slug: #{slug}")
    return clean_slug(slug, klass)
  end

  private

  # In certain cases (like turning on auto slug for an agent)
  # we'll want to get all the name and authority data without doing a bunch of DB queries.
  def self.get_json_for_agent(agent_record, klass)
    debug("called with params", "agent_record: #{agent_record.inspect} klass: #{klass.to_s}")


    klass.to_jsonmodel(agent_record).display_name
  end

end