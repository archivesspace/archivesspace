module ResultInfo
  extend ActiveSupport::Concern

  # extract the repository agent info
  def process_repo_info(result)
    info = {}
    info['top'] = {}
    unless result['_resolved_repository'].blank? ||  result['_resolved_repository']['json'].blank?
      repo =  result['_resolved_repository']['json']
      %w(name uri url parent_institution_name image_url).each do | item |
        info['top'][item] = repo[item] unless repo[item].blank?
      end
      unless repo['agent_representation'].blank? || repo['agent_representation']['_resolved'].blank? || repo['agent_representation']['_resolved']['jsonmodel_type'] != 'agent_corporate_entity'
        in_h = repo['agent_representation']['_resolved']['agent_contacts'][0]
        %w{city region post_code country email }.each do |k|
          info[k] = in_h[k] if in_h[k].present?
        end
        if in_h['address_1'].present?
          info['address'] = []
          [1,2,3].each do |i|
            info['address'].push(in_h["address_#{i}"]) if in_h["address_#{i}"].present?
          end
        end
        info['telephones'] = in_h['telephones'] if !in_h['telephones'].blank?
      end
    end
   info
  end
# create a usable agent hash
  def process_agents(agents_arr)
    agents_h = {}
    agents_arr.each do |agent|
      unless agent['role'].blank? || agent['_resolved'].blank? 
        role = agent['role']
        ag = title_and_uri(agent['_resolved'])
        agents_h[role] = agents_h[role].blank? ? [ag] : agents_h[role].push(ag) if ag
      end
    end
    agents_h
  end

# create a usable subjects array
  def process_subjects(subjects_arr)
    return_arr = []
    subjects_arr.each do |subject|
      unless subject['_resolved'].blank?
        sub = title_and_uri(subject['_resolved'])
        return_arr.push(sub) if sub
      end
    end
    return_arr
  end

# return a title/uri hash if publish == true
  def title_and_uri(in_h)
    if in_h['publish']
      return in_h.slice('uri', 'title')
    else
      return nil
    end
  end

# look for a representative instance

  def get_rep_image(instances)
    rep = {}
    if instances && instances.kind_of?(Array)
      instances.each do |instance|
        unless instance['digital_object'].blank? || instance['digital_object']['_resolved'].blank? 
          it =  instance['digital_object']['_resolved']
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

# digital object processing 
  def process_digital(json)
    dig = {}
    unless json['digital_object_id'].blank? ||  !json['digital_object_id'].start_with?('http')
      dig['out'] = json['digital_object_id']
    end
    dig = process_file_versions(json, dig)
  end

# representative digital object for an archival object
  def process_digital_instance(instances)
    dig = {}
    if instances && instances.kind_of?(Array)
      instances.each do |instance|
        unless instance['digital_object'].blank? || instance['digital_object']['_resolved'].blank?
          it =  instance['digital_object']['_resolved']
           unless !it['publish'] || it['file_versions'].blank?
             dig = process_file_versions(it, dig)
           end
        end
        break if !dig.blank?
      end
    end
    dig
  end

  def process_file_versions(json, dig)
    unless json['file_versions'].blank?
      json['file_versions'].each do |version|
        if version['publish'] && version['file_uri'].start_with?('http')
          if !version['xlink_show_attribute'].blank? && (version['xlink_show_attribute']||'') == 'embed'
            dig['thumb'] = (dig['thumb']? dig['thumb'].push(version['file_uri']) : [version['file_uri']])
            unless json['html'].blank? || json['html']['note'].blank?
              dig['caption'] =  json['html']['note']['note_text']
              dig['caption'] = dig['caption'].html_safe if dig['caption']
            end
          elsif (version['xlink_show_attribute']||'') == 'new'
            dig['out'] = version['file_uri'] if version['file_uri'] != (dig['out'] || '')
          end
        end
      end
    end
    dig
  end
end
