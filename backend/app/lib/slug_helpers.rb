module SlugHelpers
  def self.get_id_from_slug(slug, controller, action)
  	rec, table = case controller

  	# based on the controller/action, query the right table for the slug
  	when "repositories"
  		[Repository.where(:slug => slug).first, "repository"]
    when "resources"
      [Resource.any_repo.where(:slug => slug).first, "resource"]
    when "objects"
      [DigitalObject.any_repo.where(:slug => slug).first, "digital_object"]
    when "accessions"
      [Accession.any_repo.where(:slug => slug).first, "accession"]
    when "subjects"
      [Subject.any_repo.where(:slug => slug).first, "subject"]
  	end

  	# BINGO!
  	if rec
  		return [rec[:id], table, rec[:repo_id]]

  	# Always return -1 if we can't find that slug
  	else
  		return [-1, table, -1]
  	end
  end

  # given a slug, return true if slug is used by another entitiy.
  # return false otherwise.
  def self.slug_in_use?(slug)
    repo_count           = Repository.where(:slug => slug).count
    resource_count       = Resource.where(:slug => slug).count
    subject_count        = Subject.where(:slug => slug).count
    digital_object_count = DigitalObject.where(:slug => slug).count
    accession_count      = Accession.where(:slug => slug).count
    classification_count = Classification.where(:slug => slug).count

    return repo_count + 
           resource_count + 
           subject_count + 
           accession_count + 
           classification_count + 
           digital_object_count > 0
  end

  # dupe_slug is already in use. Recusively find a suffix (e.g., slug_1)
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