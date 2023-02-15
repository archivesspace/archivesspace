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

  def snac_identifiers(identifiers)
    identifiers.select { |id| id['source'] == 'snac' }
  end

  def find_dates_for(result)
    dates = result.json.fetch('dates_of_existence', [])
    dates + result.json['names'].map {|names| names['use_dates']}.flatten
  end

  def display_date_type?(type)
    type && type != 'standard'
  end

  def display_date_type(type, value)
    "(" + I18n.t("enumerations.#{type}.#{value}") + ")"
  end

  def representative_link_to_digital_materials?(record)
    record.primary_type == 'resource'
  end

  def nl2ws(text)
    text = text.join(' ') if text.respond_to? :each
    sanitize(text).gsub(/\n/, ' ').html_safe
  end

  def uri?(uri_candidate)
    uri_candidate =~ /^#{URI::DEFAULT_PARSER.make_regexp}$/
  end

  def display_used_language(language)
    lang = ''
    lang.concat("<b>#{I18n.t('language_and_script.language')}:</b> ") if language['language'] && language['script']
    lang.concat("#{I18n.t("enumerations.language_iso639_2.#{language['language']}")}") if language['language']
    return sanitize(lang) unless language['script']

    lang.concat('. ') if language['language'] # separator
    lang.concat("<b>#{I18n.t('language_and_script.script')}:</b> ")
    lang.concat(I18n.t("enumerations.script_iso15924.#{language['script']}"))
    sanitize(lang)
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
