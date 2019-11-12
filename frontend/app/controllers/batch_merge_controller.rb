class BatchMergeController < ApplicationController

  set_access_control  "manage_container_profile_record" => [:container_profiles]

  def container_profiles
    merge_records(params[:record_uris], 'container_profile')
  end

  private

  def merge_records(uris, record_type)
    target = uris[0]
    uris.shift
    victims = uris
    handle_merge( victims,
                  target,
                  record_type)
  end


end
