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




end
