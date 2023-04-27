module ResultInfo
  extend ActiveSupport::Concern

  # create the breadcrumbs
  def breadcrumb_info
    context = [] # FIXME get_path(@tree)
    path = [] # FIXME @tree.dig('path_to_root')
    unless !path || !path.is_a?(Array) || path.size == 0
      type = path[0].dig('node_type')
      unless type == 'repository' || !@repo_info.dig('top', 'uri')
        context.unshift({:uri => @repo_info['top']['uri'],
                          :crumb => strip_mixed_content(@repo_info['top']['name'])})
      end
    end
    context.push({:uri => '', :crumb => strip_mixed_content(@result['json']['display_string'] || @result['json']['title']) })
    context
  end

  def fill_request_info
    @request = @result.request_item

    @request
  end


  # handle dates
  def handle_dates(json)
    json['html'] = {} if !json.dig('html')
    json['html']['dates'] = []
    json['dates'].each do |date|
      label = date['label'].blank? ? '' : "#{date['label'].titlecase}: "
      label = '' if label == 'Creation: '
      exp = date['expression'] || ''
      if exp.blank?
        exp = date['begin'] unless date['begin'].blank?
        unless date['end'].blank?
          exp = (exp.blank? ? '' : exp + '-') + date['end']
        end
      end
      if date['date_type'] == 'bulk'
        exp = exp.sub('bulk', '').sub('()', '').strip
        exp = date['begin'] == date['end'] ? I18n.t('bulk._singular', :dates => exp) :
          I18n.t('bulk._plural', :dates => exp)
      end
      json['html']['dates'].push({'final_expression' => label + exp, '_inherited' => date.dig('_inherited')})
    end
  end

  def handle_external_docs(json)
    unless !json.has_key?('external_documents') || json['external_documents'].blank?
      json['html'] = {} if !json.dig('html')
      json['html']['external_documents'] = []
      json['external_documents'].each do |doc|
        if doc['publish']
          extd = {}
          extd['title'] = doc['title']
          extd['uri'] = doc['location'].start_with?('http') ? doc['location'] : ''
          json['html']['external_documents'].push(extd)
        end
      end
    end
  end

  # extract the repository agent info
  def process_repo_info(repo)
    info = {}
    info['top'] = {}
    unless repo.nil?
      %w(name uri url parent_institution_name image_url repo_code description).each do |item|
        info['top'][item] = repo[item] unless repo[item].blank?
      end
      unless repo['agent_representation'].blank? || repo['agent_representation']['_resolved'].blank? || repo['agent_representation']['_resolved']['agent_contacts'].blank? || repo['agent_representation']['_resolved']['jsonmodel_type'] != 'agent_corporate_entity'
        in_h = repo['agent_representation']['_resolved']['agent_contacts'][0]
        %w{city region post_code country email }.each do |k|
          info[k] = in_h[k] if in_h[k].present?
        end
        if in_h['address_1'].present?
          info['address'] = []
          [1, 2, 3].each do |i|
            info['address'].push(in_h["address_#{i}"]) if in_h["address_#{i}"].present?
          end
        end
        info['telephones'] = in_h['telephones'] if !in_h['telephones'].blank?
      end
    end
    info
  end

# create a usable agent hash
  def process_agents(agents_arr, subjects_arr = [])
    agents_h = {}
    agents_arr.each do |agent|
      unless agent['role'].blank? || agent['_resolved'].blank?
        role = agent['role']
        if role == 'subject'
          subjects_arr.push(agent['_resolved'])
        elsif ag
          agents_h[role] = agents_h[role].blank? ? [ag] : agents_h[role].push(ag)
        end
      end
    end
    subjects_arr.sort_by! { |hsh| hsh['title'] }
    agents_h
  end

# digital object processing
  def process_digital(json)
    dig_obj = {}
    unless json['digital_object_id'].blank? || !json['digital_object_id'].start_with?('http')
      dig_obj['out'] = json['digital_object_id']
    end
    dig_obj = process_file_versions(json)
    unless dig_obj.blank?
      dig_obj['material'] = json['digital_object_type'].blank? ? '' : '(' << json['digital_object_type'] << ')'
      caption = json.fetch(json['display_string'], json['title'])
      caption = '' if caption.blank?
      dig_obj['caption'] = CGI::escapeHTML(strip_mixed_content(caption)) if dig_obj['caption'].blank? && !dig_obj['thumb'].blank?
    end
    dig_obj.blank? ? [] : [dig_obj]
  end


# process extents for display; format per Mark Custer
  def process_extents(json)
    unless json['extents'].blank?
      json['html'] = {} if !json.dig('html')
      json['html']['extents'] = []
      json['extents'].each do |ext|
        display = ''
        type = I18n.t("enumerations.extent_extent_type.#{ext['extent_type']}", default: ext['extent_type'])
        display = I18n.t('extent_number_type', :number => ext['number'], :type => type)
        summ = ext['container_summary'] || ''
        summ = "(#{summ})" unless summ.blank? || ( summ.start_with?('(') && summ.end_with?(')'))  # yeah, I coulda done this with rexep.
        display << ' ' << summ
        display << I18n.t('extent_phys_details', :deets => ext['physical_details']) unless ext['physical_details'].blank?
        display << I18n.t('extent_dims', :dimensions => ext['dimensions']) unless ext['dimensions'].blank?
        json['html']['extents'].push({'display' => display, '_inherited' => ext.dig('_inherited')})
      end
    end
  end

# representative digital object for an archival object
  def process_digital_instance(instances)
    dig_objs = []
    if instances && instances.is_a?(Array)
      instances.each do |instance|
        unless !instance.dig('digital_object', '_resolved')
          dig_f = {}
          it =  instance['digital_object']['_resolved']
          unless !it['publish'] || it['file_versions'].blank?
            title = strip_mixed_content(it['title'])
            dig_f = process_file_versions(it)
            dig_f['caption'] = CGI::escapeHTML(title) if dig_f['caption'].blank? && !title.blank?
          end
          dig_f['material'] = it['digital_object_type'].blank? ? '' : '(' << it['digital_object_type'] << ')'
        end
        dig_objs.push(dig_f) unless dig_f.blank?
      end
    end
    dig_objs
  end

  # get links (including thumbnail, caption) for *one* digital object
  def process_file_versions(json)
    dig_f = {}
    unless json['file_versions'].blank?
      embed_caption = ''
      rep_caption = ''
      json['file_versions'].each do |version|
        version['file_uri'].strip!
        if version.dig('publish') != false && (version['file_uri'].start_with?('http') ||
          version['file_uri'].start_with?('data:'))

          if version.dig('xlink_show_attribute') == 'embed'
            dig_f['thumb'] = version['file_uri']
            dig_f['represent'] = 'embed' if version['is_representative']
            # For an embedded file version, if the caption is empty,
            # 1. set the embed_caption to the title
            # 2. set the rep_caption to the title if it is a representative version
            if version['caption'].blank?
              embed_caption = version['title']
              rep_caption = version['title'] if version['is_representative']
            else
              # For an embedded file version, if the caption is not empty,
              # 1. set the embed_caption to the caption
              # 2. set the rep_caption to the caption if it is a representative version
              embed_caption = version['caption']
              rep_caption = version['caption'] if version['is_representative']
            end
          else
            dig_f['represent'] = 'new' if version['is_representative']
            dig_f['out'] = version['file_uri'] if version['file_uri'] != (dig_f['out'] || '')
            # if the caption is empty set the rep_caption to the title
            if version['caption'].blank?
              rep_caption = version['title']
            else
              # if the caption is not empty set the rep_caption to the caption
              rep_caption = version['caption']
            end
          end
        elsif !version['file_uri'].start_with?('http')
          Rails.logger.debug("****BAD URI? #{version['file_uri']}")
        end
      end
    end
    # Use the representative caption for the caption in the PUI if there is a
    # representative caption
    if !rep_caption.blank?
      dig_f['caption'] = rep_caption
    elsif !embed_caption.blank?
      # Use the embed caption for the caption in the PUI if there is isn't a
      # representative caption but there is an embedded caption
      dig_f['caption'] = rep_caption
    end
    dig_f
  end

# create a usable subjects array
  def process_subjects(subjects_arr)
    return_arr = []
    subjects_arr.each do |subject|
      unless subject['_resolved'].blank?
        return_arr.push(subject['_resolved'])
      end
    end
    return_arr
  end

# look for a representative instance
  def get_rep_image(instances)
    rep = {}
    if instances && instances.is_a?(Array)
      instances.each do |instance|
        unless instance['digital_object'].blank? || instance['digital_object']['_resolved'].blank?
          it = instance['digital_object']['_resolved']
          unless !it['publish'] || it['file_versions'].blank?
            it['file_versions'].each do |ver|
              if ver['is_representative'] && ver['xlink_show_attribute'] == 'embed' && ver['publish']
                rep['title'] = strip_mixed_content(it['title'])
                rep['uri'] = ver['file_uri']
              end
            end
          end
        end
      end
    end
    rep
  end

end
