module SlugHelpers
  # Find the record given the slug, return id, repo_id, and table name.
  # This is a gnarly descision tree because the query we'll run depends on which
  # controller is asking, and whether we're scoping by repo slug or not.

  def self.get_id_from_slug(slug, controller, action, repo_slug)
    # First, we'll check if we're looking for a non-repo scoped entity, since these are straight queries.
    if controller == "repositories"
      rec = Repository.where(:slug => slug).first
      table = "repository"
    elsif controller == "agents"
      rec, table = self.find_slug_in_agent_tables(slug)
    elsif controller == "subjects"
      rec = Subject.where(:slug => slug).first
      table = "subject"

    # All other entities can be repo scoped or not, so we'll call either the repo sensitive or insensitive method depending on the config setting.
    elsif AppConfig[:repo_slug_in_URL]
      if controller == "objects"
        rec, table = self.find_slug_in_object_tables_with_repo(slug, repo_slug)
      else
        rec, table = find_in_repo(slug, controller, action, repo_slug)
      end
    else
      if controller == "objects"
        rec, table = self.find_slug_in_object_tables_any_repo(slug)
      else
        rec, table = find_any_repo(slug, controller, action)
      end
    end

  	if rec
  		return [rec[:id], table, rec[:repo_id]]

  	# Always return -1 if we can't find that slug
  	else
  		return [-1, table, -1]
  	end
  end

  # remove invalid chars, truncate, and dedupe slug if necessary
  def self.clean_slug(slug, klass)
    # replace spaces with underscores
    slug = slug.gsub(" ", "_")

    # remove URL-reserved chars
    slug = slug.gsub(/[&;?$<>#%{}|\\^~\[\]`\/@=:+,!.]/, "")

    # enforce length limit of 50 chars
    slug = slug.slice(0, 50)

    # replace any multiple underscores with a single underscore
    slug = slug.gsub(/_[_]+/, "_")

    # remove any leading or trailing underscores
    slug = slug.gsub(/^_/, "").gsub(/_$/, "")

    # if slug is numeric, add a leading '_'
    # this is necessary, because numerical slugs will be interpreted as an id by the controller
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
        thing[:slug] = thing.format_multipart_identifier
      end

    elsif thing.class == Accession
      thing[:slug] = thing.format_multipart_identifier

    elsif thing.class == Classification || thing.class == ClassificationTerm
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

  # Generates URLs for display in hirearchial tree links in public interface for Archival Objects and Digital object components
  def self.get_slugged_url_for_largetree(jsonmodel_type, repo_id, slug)
    if slug && AppConfig[:use_human_readable_URLs]
      if AppConfig[:repo_slug_in_URL]
        repo = Repository.first(:id => repo_id)
        repo_slug = repo && repo.slug ? repo.slug : ""

        if repo_slug.empty?
          return "#{AppConfig[:public_proxy_url]}/#{jsonmodel_type.underscore}s/#{slug}"
        else
          return "#{AppConfig[:public_proxy_url]}/repositories/#{repo_slug}/#{jsonmodel_type.underscore}s/#{slug}"
        end
      else
        return "#{AppConfig[:public_proxy_url]}/#{jsonmodel_type.underscore}s/#{slug}"
      end
    else
      return ""
    end
  end

  # determine if our record has updated a data field that a field depends on.
  # slug will be updated iff this method returns true
  def self.slug_data_updated?(obj)
    id_field_changed        = false
    name_field_changed      = false

    slug_field_changed = obj.column_changed?(:slug)
    slug_auto_field_changed = obj.column_changed?(:is_slug_auto)

    case obj.class.to_s
    when "Resource"
      if AppConfig[:generate_resource_slugs_with_eadid]
        id_field_changed = obj.column_changed?(:ead_id)
      else
        id_field_changed = obj.column_changed?(:identifier)
      end

      name_field_changed = obj.column_changed?(:title)

    when "Accession"
      id_field_changed = obj.column_changed?(:identifier)
      name_field_changed = obj.column_changed?(:title)

    when "DigitalObject"
      id_field_changed = obj.column_changed?(:digital_object_id)
      name_field_changed = obj.column_changed?(:title)

    when "DigitalObjectComponent"
      id_field_changed = obj.column_changed?(:component_id)
      name_field_changed = obj.column_changed?(:title)

    when "Classification"
      id_field_changed = obj.column_changed?(:identifier)
      name_field_changed = obj.column_changed?(:title)

    when "ClassificationTerm"
      id_field_changed = obj.column_changed?(:identifier)
      name_field_changed = obj.column_changed?(:title)

    when "Repository"
      id_field_changed = obj.column_changed?(:repo_code)
      name_field_changed = obj.column_changed?(:name)

    when "ArchivalObject"
      id_field_changed = obj.column_changed?(:ref_id)
      name_field_changed = obj.column_changed?(:title)

    when "Subject"
      id_field_changed = obj.column_changed?(:title)
      name_field_changed = obj.column_changed?(:title)

    # for agent objects, the fields we need are in a different table.
    # since we don't have access to that object here, we'll always process slugs for agents.
    when "AgentCorporateEntity"
      id_field_changed = true
      name_field_changed = true

    when "AgentPerson"
      id_field_changed = true
      name_field_changed = true

    when "AgentFamily"
      id_field_changed = true
      name_field_changed = true

    when "AgentSoftware"
      id_field_changed = true
      name_field_changed = true
    end

    # auto-gen slugs has been switched from OFF to ON
    if slug_auto_field_changed && obj[:is_slug_auto] == 1
      return true

    # auto-gen slugs is OFF, and slug field updated
    elsif obj[:is_slug_auto] == 0 && slug_field_changed
      return true

    # auto-gen slugs is ON based on name, and name has changed
    elsif !AppConfig[:auto_generate_slugs_with_id] && name_field_changed
      return true

    # auto-gen slugs is ON based on id, and id has changed
    elsif AppConfig[:auto_generate_slugs_with_id] && id_field_changed
      return true

    # any other case, we can skip slug processing
    else
      return false
    end
  end

  private

  # based on the controller/action, query the right table for the slug
  # in repo with repo.slug == repo_slug

  # FIXME: Queries like: Resource.where(:slug => slug, :repo_id => repo.id)
  # fail with "missing repo_id for request" error (in ASModel_CRUD) for some reason. Using SQL queries to get around this for now.
  def self.find_in_repo(slug, controller, action, repo_slug)
    repo = Repository.where(:slug => repo_slug).first

    table = case controller
    when "resources"
      "resource"
    when "accessions"
      "accession"
    when "classifications"
      if action == "term"
        "classification_term"
      else
        "classification"
      end
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
    when "accessions"
      [Accession.any_repo.where(:slug => slug).first, "accession"]
    when "classifications"
      if action == "term"
        [ClassificationTerm.any_repo.where(:slug => slug).first, "classification_term"]
      else
        [Classification.any_repo.where(:slug => slug).first, "classification"]
      end
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

  # find slug in one of the object tables, only in the specified repo.

  # FIXME: Queries like: ArchivalObject.where(:slug => slug, :repo_id => repo.id)
  # fail with "missing repo_id for request" error (in ASModel_CRUD) for some reason. Using SQL queries to get around this for now.

  def self.find_slug_in_object_tables_with_repo(slug, repo_slug)
    repo = Repository.where(:slug => repo_slug).first
    found_in = nil

    # NO REPO - find the right table so that public interface knows what route to render
    if repo.nil?
      obj = Repository.fetch("SELECT * FROM archival_object where slug = ?", slug).first
      found_in = "archival_object" if obj

      unless found_in
        obj = Repository.fetch("SELECT * FROM digital_object where slug = ?", slug).first
        found_in = "digital_object" if obj
      end

      unless found_in
        obj = Repository.fetch("SELECT * FROM digital_object_component where slug = ?", slug).first
        found_in = "digital_object_component" if obj
      end

      unless found_in
        obj = nil
      end

      return [nil, found_in]

    # REPO FOUND - find entity
    else
      obj = Repository.fetch("SELECT * FROM archival_object where slug = ? and repo_id = ?", slug, repo.id).first
      found_in = "archival_object" if obj

      unless found_in
        obj = Repository.fetch("SELECT * FROM digital_object where slug = ? and repo_id = ?", slug, repo.id).first
        found_in = "digital_object" if obj
      end

      unless found_in
        obj = Repository.fetch("SELECT * FROM digital_object_component where slug = ? and repo_id = ?", slug, repo.id).first
        found_in = "digital_object_component" if obj
      end

      unless found_in
        obj = nil
      end

      return [obj, found_in]
    end
  end

  # find slug in one of the object tables in any repo.
  def self.find_slug_in_object_tables_any_repo(slug)
    found_in = nil

    obj = ArchivalObject.any_repo.where(:slug => slug).first
    found_in = "archival_object" if obj

    unless found_in
      obj = DigitalObject.any_repo.where(:slug => slug).first
      found_in = "digital_object" if obj
    end

    unless found_in
      obj = DigitalObjectComponent.any_repo.where(:slug => slug).first
      found_in = "digital_object_component" if obj
    end

    unless found_in
      obj = nil
    end

    return [obj, found_in]
  end


  # given a slug, return true if slug is used by another entity.
  # return false otherwise.
  def self.slug_in_use?(slug, klass)
    repo_count           = Repository.where(:slug => slug).count
    resource_count       = Resource.where(:slug => slug).count
    subject_count        = Subject.where(:slug => slug).count
    digital_object_count = DigitalObject.where(:slug => slug).count
    accession_count      = Accession.where(:slug => slug).count
    classification_count = Classification.where(:slug => slug).count
    class_term_count     = ClassificationTerm.where(:slug => slug).count
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
    when ClassificationTerm
      class_term_count -= 1 if class_term_count > 0
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
           class_term_count +
           agent_person_count +
           agent_family_count +
           agent_corp_count +
           agent_software_count +
           digital_object_count +
           archival_obj_count +
           do_component_count > 0
  end

  # dupe_slug is already in use. Recursively find a suffix (e.g., slug_1)
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


end
