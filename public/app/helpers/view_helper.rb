module ViewHelper
  #TODO: figure out a clever way to DRY these helpers up.

  # returns repo URL via slug if defined, via ID it not.
  def repository_base_url(result)
    if result['slug'] && AppConfig[:use_human_readable_urls]
      url = "repositories/" + result['slug']
    else
      url = result['uri']
    end

    return url
  end

  def resource_base_url(result)
    if result.json['slug'] && AppConfig[:use_human_readable_urls]
      # Generate URLs with repo slugs if turned on
      if AppConfig[:repo_name_in_slugs]
        if result.resolved_repository["slug"]
          url = "repositories/#{result.resolved_repository["slug"]}/resources/" + result.json['slug']

        # just use ids if repo has no slug
        else
          url = result['uri']
        end

      # otherwise, generate URL without repo slug
      else
        url = "resources/" + result.json['slug']
      end

    # object has no slug
    else
      url = result['uri']
    end

    return url
  end

  def digital_object_base_url(result)
    if result.json['slug'] && AppConfig[:use_human_readable_urls]
      if AppConfig[:repo_name_in_slugs]
        if result.resolved_repository["slug"]
          url = "repositories/#{result.resolved_repository["slug"]}/digital_objects/" + result.json['slug']
        else
          url = result['uri']
        end

      # otherwise, generate URL without repo slug
      else
        url = "digital_objects/" + result.json['slug']
      end
    else
      url = result['uri']
    end

    return url
  end

  def accession_base_url(result)
    if result.json['slug'] && AppConfig[:use_human_readable_urls]
      if AppConfig[:repo_name_in_slugs]
        if result.resolved_repository["slug"]
          url = "repositories/#{result.resolved_repository["slug"]}/accessions/" + result.json['slug']
        else
          url = result['uri']
        end

      # otherwise, generate URL without repo slug
      else
        url = "accessions/" + result.json['slug']
      end
    else
      url = result['uri']
    end

    return url
  end

  def subject_base_url(result)
    if result.json['slug'] && AppConfig[:use_human_readable_urls]
      url = "subjects/" + result.json['slug']
    else
      url = result['uri']
    end

    return url
  end

  def classification_base_url(result)
    if result.json['slug'] && AppConfig[:use_human_readable_urls]
      if AppConfig[:repo_name_in_slugs]
        if result.resolved_repository["slug"]
          url = "repositories/#{result.resolved_repository["slug"]}/classifications/" + result.json['slug']
        else
          url = result['uri']
        end

      # otherwise, generate URL without repo slug
      else
        url = "classifications/" + result.json['slug']
      end
    else
      url = result['uri']
    end

    return url
  end

  def agent_base_url(result)
    if result.json['slug'] && AppConfig[:use_human_readable_urls]
      url = "agents/" + result.json['slug']
    else
      url = result['uri']
    end

    return url
  end

  def archival_object_base_url(result)
    if result.json['slug'] && AppConfig[:use_human_readable_urls]
      if AppConfig[:repo_name_in_slugs]
        if result.resolved_repository["slug"]
          url = "repositories/#{result.resolved_repository["slug"]}/archival_objects/" + result.json['slug']
        else
          url = result['uri']
        end

      # otherwise, generate URL without repo slug
      else
        url = "archival_objects/" + result.json['slug']
      end
    else
      url = result['uri']
    end

    return url
  end
end
