module ViewHelper
  def show_agents_sidebar?(agent)
    agent.json['names'].length > 1 ||
      (agent.respond_to?(:related_agents) && ASUtils.wrap(agent.related_agents).any?) ||
      (agent.respond_to?(:external_documents) && ASUtils.wrap(agent.external_documents).any?) ||
      (agent.json['agent_resources'] && ASUtils.wrap(agent.json['agent_resources']).any?)
  end

  def inherited?(item)
    (item.key?('_inherited') && item['_inherited']) || (item.key?('is_inherited') && item['is_inherited'])
  end

  def all_inherited?(items)
    items.all? { |item| inherited?(item) }
  end

  def display_component_id(record, infinite_item)
    return nil if record.identifier.blank? || (infinite_item && record.json.key?('component_id_inherited'))

    record.identifier
  end

  # Only display if identifier is a URL
  # URL Regex from: https://stackoverflow.com/questions/3809401/what-is-a-good-regular-expression-to-match-a-url %>
  # TODO: configurable?
  DISPLAYABLE_IDENTIFIER_REGEX = /(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,})/.freeze
  def lookup_displayable_identifiers(identifiers)
    identifiers.select { |id| id['record_identifier'] =~ DISPLAYABLE_IDENTIFIER_REGEX && id['source_enum'] == 'snac' }
  end

  def find_dates_for(result)
    dates = result.json.fetch('dates_of_existence', [])
    dates + result.json['names'].map{|names| names['use_dates']}.flatten
  end

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
