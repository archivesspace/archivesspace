module SlugHelpers
  # Find the record given the slug, return id, repo_id, and table name.
  def self.get_id_from_slug(slug, controller, action, repo_slug)

    # global scope tables first
    if controller == "repositories"
      rec = Repository.where(:slug => slug).first 
      table = "repository"
    elsif controller == "agents"
      rec, table = self.find_slug_in_agent_tables(slug)
    elsif controller == "subjects"
      rec = Subject.where(:slug => slug).first 
      table = "subject"

    # repo scope tables
    elsif AppConfig[:repo_name_in_slugs] 
      rec, table = find_in_repo(slug, controller, action, repo_slug)
    else
      rec, table = find_any_repo(slug, controller, action)
    end

  	if rec
  		return [rec[:id], table, rec[:repo_id]]

  	# Always return -1 if we can't find that slug
  	else
  		return [-1, table, -1]
  	end
  end

  # based on the controller/action, query the right table for the slug
  # in repo with repo.slug == repo_slug
  
  # FIXME: Queries like: Resource.where(:slug => slug, :repo_id => repo.id)
  # fail with "missing repo_id for request" error (in ASModel_CRUD) for some reason. Using SQL queries to get around this for now. 
  def self.find_in_repo(slug, controller, action, repo_slug)
    repo = Repository.where(:slug => repo_slug).first

    table = case controller
    when "resources"
      "resource"
    when "objects"
      "digital_object"
    when "accessions"
      "accession"
    when "classifications"
      "classification"
    else
      puts "++++++++++++++++++++++++++++"
      puts "controller: " + controller.to_s

    end

    if repo.nil?
      return [nil, table]
    else
      return [Repository.fetch("SELECT * FROM #{table} where slug = ? and repo_id = ?", slug, repo.id).first, table]
    end
  end

  # based on the controller/action, query the right table for the slug in any repo
  def self.find_any_repo(slug, controller, action)
    return case controller
    when "resources"
      [Resource.any_repo.where(:slug => slug).first, "resource"]
    when "objects"
      [DigitalObject.any_repo.where(:slug => slug).first, "digital_object"]
    when "accessions"
      [Accession.any_repo.where(:slug => slug).first, "accession"]
    when "classifications"
      [Classification.any_repo.where(:slug => slug).first, "classification"]
    end
  end

  # our slug could be in one of four tables.
  # we'll look and see, one table at a time.
  def self.find_slug_in_agent_tables(slug)
    found_in = nil

    agent = AgentPerson.where(:slug => slug).first
    found_in = "agent_person" if agent

    unless found_in
      agent = AgentFamily.where(:slug => slug).first
      found_in = "agent_family" if agent
    end

    unless found_in
      agent = AgentCorporateEntity.where(:slug => slug).first
      found_in = "agent_corporate_entity" if agent
    end

    unless found_in
      agent = AgentSoftware.where(:slug => slug).first
      found_in = "agent_software" if agent
    end

    unless found_in
      agent = nil
    end

    return [agent, found_in]
  end

  # given a slug, return true if slug is used by another entitiy.
  # return false otherwise.
  def self.slug_in_use?(slug, klass)
    repo_count           = Repository.where(:slug => slug).count
    resource_count       = Resource.where(:slug => slug).count
    subject_count        = Subject.where(:slug => slug).count
    digital_object_count = DigitalObject.where(:slug => slug).count
    accession_count      = Accession.where(:slug => slug).count
    classification_count = Classification.where(:slug => slug).count
    agent_person_count   = AgentPerson.where(:slug => slug).count
    agent_family_count   = AgentFamily.where(:slug => slug).count
    agent_corp_count     = AgentCorporateEntity.where(:slug => slug).count
    agent_software_count = AgentSoftware.where(:slug => slug).count
    archival_obj_count   = ArchivalObject.where(:slug => slug).count
    do_component_count   = DigitalObjectComponent.where(:slug => slug).count

    # We don't want to count a slug as in use if it's being used by 
    # the record we're calling this method for. 
    # To fix that false positive case:
    # if a count for a class is > 0 and that's the same class that's de-duping
    # decrement the count by one to account for the calling object

    case klass
    when Repository
      repo_count -= 1 if repo_count > 0
    when Resource
      resource_count -= 1 if resource_count > 0
    when Subject
      subject_count -= 1 if subject_count > 0
    when DigitalObject
      digital_object_count -= 1 if digital_object_count > 0
    when Accession
      acccession_count -= 1 if accession_count > 0
    when Classification
      classification_count -= 1 if classification_count > 0
    when AgentPerson
      agent_person_count -= 1 if agent_person_count > 0
    when AgentFamily
      agent_family_count -= 1 if agent_family_count > 0
    when AgentCorporateEntity
      agent_corp_count -= 1 if agent_corp_count > 0
    when AgentSoftware
      agent_software_count -= 1 if agent_software_count > 0
    when ArchivalObject
      archival_obj_count -= 1 if archival_obj_count > 0
    when DigitalObjectComponent
      do_component_count -= 1 if do_component_count > 0
    end

    return repo_count + 
           resource_count + 
           subject_count + 
           accession_count + 
           classification_count + 
           agent_person_count + 
           agent_family_count + 
           agent_corp_count + 
           agent_software_count + 
           digital_object_count +
           archival_obj_count +
           do_component_count > 0
  end

  # dupe_slug is already in use. Recusively find a suffix (e.g., slug_1)
  # that isn't used by anything else
  def self.dedupe_slug(dupe_slug, count = 1, klass)
    new_slug = dupe_slug + "_" + count.to_s

    if slug_in_use?(new_slug, klass)
      dedupe_slug(dupe_slug, count + 1, klass)
    else
      return new_slug
    end
  end

  def self.get_agent_name(id, klass)
    case klass.to_s
    when "AgentPerson"
      table = "name_person"
      lookup_field_prefix = "agent_person"
      select_field = "primary_name"
    when "AgentFamily"
      table = "name_family"
      lookup_field_prefix = "agent_family"
      select_field = "family_name"
    when "AgentCorporateEntity"
      table = "name_corporate_entity"
      lookup_field_prefix = "agent_corporate_entity"
      select_field = "primary_name"
    when "AgentSoftware"
      table = "name_software"
      lookup_field_prefix = "agent_software"
      select_field = "software_name"
    end

    rec = AgentContact.fetch("SELECT #{select_field} FROM #{table} where #{lookup_field_prefix}_id = ?", id).first

    if rec
      return rec[select_field.to_sym]
    else
      return random_name
    end
  end

  def self.random_name
    (0...8).map { (65 + rand(26)).chr }.join
  end

  # remove invalid chars, truncate, and dedupe slug if necessary
  def self.clean_slug(slug, klass)
    # replace spaces with underscores
    slug = slug.gsub(" ", "_")

    # remove URL-reserved chars
    slug = slug.gsub(/[&;?$<>#%{}|\\^~\[\]`\/@=:+,!.]/, "")

    # enforce length limit of 50 chars
    slug = slug.slice(0, 50)

    # if slug is numeric, add a leading '_' 
    # this is necessary, because numerical slugs will be interpreted as an id
    if slug.match(/^(\d)+$/) 
      slug = slug.prepend("_")
    end

    # if slug is empty at this point, make something up.
    if slug.empty?
      slug = SlugHelpers.random_name
    end

    # search for dupes
    if SlugHelpers.slug_in_use?(slug, klass)
      slug = SlugHelpers.dedupe_slug(slug, 1, klass)
    end

    return slug
  end

  # auto generate a slug for this instance based on name
  def self.generate_slug_by_name!(thing)
    if !thing[:title].nil? && !thing[:title].empty?
      thing[:slug] = thing[:title]

    elsif !thing[:name].nil? && !thing[:name].empty?
      thing[:slug] = thing[:name]

    else
      # if Agent, go look in the AgentContact table.
      if thing.class == AgentCorporateEntity ||
         thing.class == AgentPerson ||
         thing.class == AgentFamily ||
         thing.class == AgentSoftware

        thing[:slug] = SlugHelpers.get_agent_name(thing.id, thing.class)

      # otherwise, make something up.
      else
        thing[:slug] = SlugHelpers.random_name
      end
    end
  end

  # auto generate a slug for this instance based on id
  def self.generate_slug_by_id!(thing)
    if thing.class == Resource 
      if AppConfig[:generate_resource_slugs_with_eadid] && thing[:ead_id]
        # use EADID if configured. Otherwise, use identifier.
        thing[:slug] = thing[:ead_id]
      else
        thing[:slug] = format_multipart_identifier(thing[:identifier])
      end

    elsif thing.class == Accession  
      thing[:slug] = format_multipart_identifier(thing[:identifier])

    elsif thing.class == Classification
      thing[:slug] = thing[:identifier]

    elsif thing.class == DigitalObject
      thing[:slug] = thing[:digital_object_id]

    elsif thing.class == Repository
      thing[:slug] = thing[:repo_code]

    elsif thing.class == ArchivalObject
      thing[:slug] = thing[:ref_id]

    elsif thing.class == DigitalObjectComponent
      thing[:slug] = thing[:component_id]

    # no identifier here!
    elsif thing.class == Subject
      thing[:slug] = thing[:title]

    # or here
    elsif thing.class == AgentCorporateEntity || AgentPerson || AgentFamily || AgentSoftware
      thing[:slug] = SlugHelpers.get_agent_name(thing.id, thing.class)
    end
  end
  
  private 

    # take a string that looks like this: "[\"3422\",\"345FD\",\"3423ASDA\",null]"
    # and convert it into this: "3422-345FD-3423ASDA"
    def self.format_multipart_identifier(identifier)
      identifier.gsub("null", '')
                .gsub!(/[\[\]]/,'')
                .gsub(",", '')
                .split('"')
                .select {|s| !s.empty?}
                .join("-")
    end 

end