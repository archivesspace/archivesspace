class JobsController < ApplicationController

  set_access_control "update_archival_record" => [:index, :new, :create]

  skip_before_filter :verify_authenticity_token


  def index
  end

  def new
    @job = JSONModel(:job).new._always_valid!
  end

  def create
    render :json => params
  end
end
