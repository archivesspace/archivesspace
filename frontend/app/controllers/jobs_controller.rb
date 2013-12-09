class JobsController < ApplicationController

  set_access_control "update_archival_record" => [:index, :new, :create]

  skip_before_filter :verify_authenticity_token


  def index
  end

  def new
    @job = JSONModel(:job).new._always_valid!
  end

  def create
    job = Job.new("ead_xml", Hash[params['files'].map {|file|
                                [file.original_filename, file.tempfile]
                              }])

    render :json => job.upload
  end
end
