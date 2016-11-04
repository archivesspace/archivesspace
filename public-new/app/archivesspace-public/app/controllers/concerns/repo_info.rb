module RepoInfo
  extend ActiveSupport::Concern

  # extract the repository agent info
  def process_repo_info(in_h)
    ret_h = {}
    %w{city region post_code country email }.each do |k|
      ret_h[k] = in_h[k] if in_h[k].present?
    end
    if in_h['address_1'].present?
      ret_h['address'] = []
      [1,2,3].each do |i|
        ret_h['address'].push(in_h["address_#{i}"]) if in_h["address_#{i}"].present?
      end
    end
    ret_h['telephones'] = in_h['telephones'] if !in_h['telephones'].blank?
    ret_h
  end



end
