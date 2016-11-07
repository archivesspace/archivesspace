module RepoInfo
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
end
