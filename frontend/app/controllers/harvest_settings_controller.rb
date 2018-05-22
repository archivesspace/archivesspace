class HarvestSettingsController < ApplicationController
  set_access_control  "manage_repository" => [:edit, :update]

  def edit
    @enum = JSONModel(:enumeration).find("/names/archival_record_level")
  end

  def update
  end
end
