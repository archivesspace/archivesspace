class BatchMergeController < ApplicationController

  set_access_control "manage_container_profile_record" => [:container_profiles]

  def container_profiles
    merge_records(params[:victims], params[:target], 'container_profile')
  end

  private

  def merge_records(victims, target, record_type)
    merge_list = victims
    target = target
    victims = merge_list - target
    handle_merge( victims,
                  target[0],
                  record_type)
  end

end
