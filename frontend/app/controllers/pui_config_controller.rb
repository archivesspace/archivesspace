class PuiConfigController < ApplicationController

  set_access_control "manage_repository" => [:edit]

  def edit
  end

end
