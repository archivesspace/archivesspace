require_relative "slug_helpers_generate"
require_relative "slug_helpers_generate_by_name"
require_relative "slug_helpers_generate_by_id"
require_relative "slug_helpers_eligibility"

module SlugHelpers

  # Find the record given the slug, return id, repo_id, and table name.
  # This is a gnarly descision tree because the query we'll run depends on which
  # controller is asking, and whether we're scoping by repo slug or not.

  def self.get_id_from_slug(slug, controller, action)
    if controller == "repositories"
      rec = Repository.where(:slug => slug).first
      table = "repository"
    elsif controller == "agents"
      rec, table = self.find_slug_in_agent_tables(slug)
    elsif controller == "subjects"
      rec = Subject.where(:slug => slug).first
      table = "subject"
    elsif controller == "objects"
      rec, table = self.find_slug_in_object_tables_any_repo(slug)
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


  # Generates URLs for display in hirearchial tree links in public interface for Archival Objects and Digital object components
  def self.get_slugged_url_for_largetree(jsonmodel_type, repo_id, slug)
    if slug && AppConfig[:use_human_readable_urls]
      if AppConfig[:repo_name_in_slugs]
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

  private

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
end
