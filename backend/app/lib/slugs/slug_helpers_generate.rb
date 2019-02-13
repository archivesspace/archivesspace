module SlugHelpers

  # remove invalid chars, truncate, and dedupe slug if necessary
  def self.clean_slug(slug, klass)
    debug("called with params", "slug: #{slug.to_s} klass: #{klass.to_s}")

    if slug
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

      # search for dupes
      if !slug.empty? && slug_in_use?(slug, klass)
        debug("deduping", "slug: #{slug.to_s} klass: #{klass.to_s}")
        slug = dedupe_slug(slug, 1, klass)
      end

    else
      slug = ""
    end

    debug("return value", slug)
    return slug
  end

  # given a slug, return true if slug is used by another entity.
  # return false otherwise.
  def self.slug_in_use?(slug, klass)
    debug("called with params", "slug: #{slug.to_s} klass: #{klass.to_s}")

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

    case klass.to_s
    when "Repository"
      repo_count -= 1 if repo_count > 0
    when "Resource"
      resource_count -= 1 if resource_count > 0
    when "Subject"
      subject_count -= 1 if subject_count > 0
    when "DigitalObject"
      digital_object_count -= 1 if digital_object_count > 0
    when "Accession"
      accession_count -= 1 if accession_count > 0
    when "Classification"
      classification_count -= 1 if classification_count > 0
    when "ClassificationTerm"
      class_term_count -= 1 if class_term_count > 0
    when "AgentPerson"
      agent_person_count -= 1 if agent_person_count > 0
    when "AgentFamily"
      agent_family_count -= 1 if agent_family_count > 0
    when "AgentCorporateEntity"
      agent_corp_count -= 1 if agent_corp_count > 0
    when "AgentSoftware"
      agent_software_count -= 1 if agent_software_count > 0
    when "ArchivalObject"
      archival_obj_count -= 1 if archival_obj_count > 0
    when "DigitalObjectComponent"
      do_component_count -= 1 if do_component_count > 0
    end

    rval = repo_count + 
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

    debug("return value", rval.to_s)
    return rval
  end

  # dupe_slug is already in use. Recursively find a suffix (e.g., slug_1)
  # that isn't used by anything else
  def self.dedupe_slug(dupe_slug, count = 1, klass)
    debug("called with params", "dupe_slug: #{dupe_slug.to_s} klass: #{klass.to_s} count: #{count.to_s}")
    
    new_slug = dupe_slug + "_" + count.to_s

    if slug_in_use?(new_slug, klass)
      dedupe_slug(dupe_slug, count + 1, klass)
    else
      return new_slug
    end
  end
end