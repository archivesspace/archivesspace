module ResourceRequestItems
  def build_request_item
    return if resolved_resource.nil?

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
    request[:cite] = cite
    request[:identifier] = identifier
    request[:title] = display_string

    note = note('accessrestrict')
    unless note.blank?
      request[:restrict] = note['note_text']
    end

    if primary_type != 'resource'
      request[:resource_id]  = (0..3).map{|i| resolved_resource.dig("id_#{i}") }.compact.join('-')
      request[:resource_name] = resolved_resource.dig('title') || ['unknown']
    end

    request[:hierarchy] = breadcrumb.reverse.drop(1).reverse.collect{|record| record[:crumb]}

    request
  end
end