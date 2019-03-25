module SlugHelpers

  # remove invalid chars and truncate slug
  def self.clean_slug(slug)

    if slug
      # if the slug contains a slash, completely zero it out.
      # this is intended to revert an entity to use the URI if the ID or name the slug was generated from is a URL.
      slug = "" if slug =~ /\//

      # downcase everything to simplify case sensitivity issues
      slug = slug.downcase

      # replace spaces with underscores
      slug = slug.gsub(" ", "_")

      # remove double hypens
      slug = slug.gsub("--", "")

      # remove single quotes
      slug = slug.gsub("'", "")

      # remove URL-reserved chars
      slug = slug.gsub(/[&;?$<>#%{}|\\^~\[\]`\/@=:+,!.]/, "")

      # enforce length limit of 50 chars
      slug = slug.slice(0, 50)

      # replace any multiple underscores with a single underscore
      slug = slug.gsub(/_[_]+/, "_")

      # remove any leading or trailing underscores
      slug = slug.gsub(/^_/, "").gsub(/_$/, "")

      # if slug is numeric, add a leading '__'
      # this is necessary, because numerical slugs will be interpreted as an id by the controller
      if slug.match(/^(\d)+$/)
        slug = slug.prepend("__")
      end

    else
      slug = ""
    end

    return slug
  end

  # runs dedupe if necessary
  def self.run_dedupe_slug(slug)
    # search for dupes
    if !slug.empty? && slug_in_use?(slug)
      dedupe_slug(slug, 1)
    else
      slug
    end
  end

  # returns true if the base slug (non-deduped) is different between slug and previous_slug
  # Examples: 
  # slug = "foo", previous_slug = "foo_1" => false
  # slug = "foo_123", previous_slug = "foo_123_1" => false
  # slug = "foo_123", previous_slug = "foo_124" => true
  # slug = "foo_123", previous_slug = "foo_124_1" => true
  def self.base_slug_changed?(slug, previous_slug)
    # first, compare the two slugs from left to right to see what they have in common. Remove anything in common.
    # Then, remove anything that matches the pattern of underscore followed by digits, like _1, _2, or _314159, etc that would indicate a deduping suffix
    # if there is nothing left, then the base slugs are the same.

    # the base slug has changed if previous_slug is nil/empty but slug is not
    if (previous_slug.nil? || previous_slug.empty?) &&
       (!slug.nil? && !slug.empty?)
      return true
    end

    # the base slug has changed if slug is nil/empty but previous_slug is not
    if (slug.nil? || slug.empty?) &&
       (!previous_slug.nil? && !previous_slug.empty?)
      return true
    end

    slug_difference = previous_slug.gsub(/^#{slug}/, "")
                                   .gsub(/_\d+$/, "")

    # the base slug has changed if there is something left over in slug_difference
    return !slug_difference.empty?
  end

  # given a slug, return true if slug is used by another entity.
  # return false otherwise.
  def self.slug_in_use?(slug)
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

    return rval
  end

  # dupe_slug is already in use. Recursively find a suffix (e.g., slug_1)
  # that isn't used by anything else
  def self.dedupe_slug(dupe_slug, count = 1)
    new_slug = dupe_slug + "_" + count.to_s

    if slug_in_use?(new_slug)
      dedupe_slug(dupe_slug, count + 1)
    else
      return new_slug
    end
  end
end
