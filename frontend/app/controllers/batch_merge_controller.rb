class BatchMergeController < ApplicationController

  set_access_control "manage_container_profile_record" => [:container_profiles]

  def container_profiles
    merge_records(params[:merge_candidates], params[:merge_destination], 'container_profile')
  end

  private

  def merge_records(merge_candidates, merge_destination, record_type)
    merge_list = merge_candidates
    merge_destination = merge_destination
    merge_candidates = merge_list - merge_destination
    handle_merge( merge_candidates,
                  merge_destination[0],
                  record_type)
  end

end
