class JobsController < ApplicationController

  set_access_control "update_archival_record" => [:index, :new, :create]

  skip_before_filter :verify_authenticity_token


  def index
    @search_data = JSONModel(:job).all(:page => selected_page, "resolve[]" => "repository")
  end

  def new
    @job = JSONModel(:job).new._always_valid!
  end

  def create
    job = Job.new(params['job']['import_type'], Hash[params['files'].map {|file|
                                [file.original_filename, file.tempfile]
                              }])

    render :json => job.upload
  end


  private

  def selected_page
    [Integer(params[:page] || 1), 1].max
  end

end
