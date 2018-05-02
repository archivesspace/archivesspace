class HarvestSettingsController < ApplicationController
  set_access_control  "manage_repository" => [:edit, :update]

  def edit
    j = JSONModel(:enumeration_value).all
    puts "++++++++++++++++++++++++++++++"
    puts j.inspect
  end

  def update
  end
end
