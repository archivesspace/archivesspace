class JobsController < ApplicationController

  set_access_control "view_repository" => [:index, :show, :log, :status, :records]
  set_access_control "import_records" => [:new, :create]
  set_access_control "cancel_importer_job" => [:cancel]


  def index
    @active_jobs = Job.active
    @search_data = Job.archived(selected_page)
  end

  def new
    @job = JSONModel(:job).new._always_valid!
    @job_types = Job.available_types.map {|e| [I18n.t("job.import_type_#{e['name']}"), e['name']]}
  end

  def create
    begin
      job = Job.new(params['job']['import_type'], Hash[Array(params['files']).reject(&:blank?).map {|file|
                                  [file.original_filename, file.tempfile]
                                }])
    rescue JSONModel::ValidationException => e
      @exceptions = e.invalid_object._exceptions
      @job = e.invalid_object

      if params[:iframePOST] # IE saviour. Render the form in a textarea for the AjaxPost plugin to pick out.
        return render_aspace_partial :partial => "jobs/form_for_iframepost", :status => 400
      else
        return render_aspace_partial :partial => "jobs/form", :status => 400
      end
    end

    if params[:iframePOST] # IE saviour. Render the form in a textarea for the AjaxPost plugin to pick out.
      render :text => "<textarea data-type='json'>#{job.upload.to_json}</textarea>"
    else
      render :json => job.upload
    end
  end


  def show
    @job = JSONModel(:job).find(params[:id], "resolve[]" => "repository")
  end


  def cancel
    Job.cancel(params[:id])

    redirect_to :action => :show
  end


  def log
    self.response_body = Enumerator.new do |y|
      Job.log(params[:id], params[:offset] || 0) do |response|
        y << response.body
      end
    end
  end


  def status
    job = JSONModel(:job).find(params[:id])

    json = {
        :status => job.status
    }

    if job.status === "queued"
      json[:queue_position] = job.queue_position
      json[:queue_position_message] = job.queue_position === 0 ? I18n.t("job._frontend.messages.queue_position_next") : I18n.t("job._frontend.messages.queue_position", :position => (job.queue_position+1).ordinalize)
    end

    render :json => json
  end


  def records
    @search_data = Job.records(params[:id], params[:page] || 1)
    render_aspace_partial :partial => "jobs/job_records"
  end

  private

  def selected_page
    [Integer(params[:page] || 1), 1].max
  end

end
