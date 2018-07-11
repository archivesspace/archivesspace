class Accession < Record

  attr_reader :related_resources, :provenance,
              :use_restrictions_note, :access_restrictions_note

  def initialize(*args)
    super

    @related_resources = parse_related_resources
    @use_restrictions_note = json['use_restrictions_note']
    @access_restrictions_note = json['access_restrictions_note']
  end

  def acquisition_type
    if json['acquisition_type']
      I18n.t("enumerations.accession_acquisition_type.#{json['acquisition_type']}", :default => json['acquisition_type'])
    end
  end

  def deaccessions
    return '' unless AppConfig[:pui_display_deaccessions]
    ASUtils.wrap(json['deaccessions'])
  end

  def content_description
    json['content_description']
  end

  def inventory
    json['inventory']
  end

  def provenance
    json['provenance']
  end

  def restrictions_apply?
    json['restrictions_apply']
  end

  def use_restrictions_note
    json['use_restrictions_note']
  end

  def access_restrictions_note
    json['access_restrictions_note']
  end

  def access_restrictions_apply?
    json['access_restrictions']
  end

  def use_restrictions_apply?
    json['use_restrictions']
  end


  private

  def parse_related_resources
    ASUtils.wrap(raw['related_resource_uris']).collect{|uri|
      if raw['_resolved_related_resource_uris']
        raw['_resolved_related_resource_uris'][uri].first
      end
    }.compact.select{|resource|
      resource['publish']
    }.map {|accession|
      record_from_resolved_json(ASUtils.json_parse(accession['json']))
    }
  end

  def build_request_item
    has_top_container = false
    container_info = build_request_item_container_info
    container_info.each {|key, value|
      if key == :top_container_url
        if ASUtils.wrap(value).any?{|v| !v.blank?}
          has_top_container = true
          break
        end
      end
    }

    return if (!has_top_container && !RequestItem::allow_nontops(resolved_repository.dig('repo_code')))

    request = RequestItem.new(container_info)

    request[:request_uri] = uri
    request[:repo_name] = resolved_repository.dig('name')
    request[:repo_code] = resolved_repository.dig('repo_code')
    request[:repo_uri] = resolved_repository.dig('uri')
    request[:repo_email] = resolved_repository.dig('agent_representation', '_resolved', 'agent_contacts', 0, 'email')
    request[:identifier] = identifier
    request[:title] = display_string
    request[:restrict] = json['access_restrictions_note']

    request
  end
end
