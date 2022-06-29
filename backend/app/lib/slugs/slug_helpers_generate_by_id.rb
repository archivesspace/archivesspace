module SlugHelpers
  # generate and return a string for a slug based on this thing's ID.
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
        slug = disp_name["authority_id"]
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

  # In certain cases (like turning on auto slug for an agent)
  # we'll want to get all the name and authority data without doing a bunch of DB queries.
  def self.get_json_for_agent(agent_record, klass)
    klass.to_jsonmodel(agent_record).display_name
  end

end
