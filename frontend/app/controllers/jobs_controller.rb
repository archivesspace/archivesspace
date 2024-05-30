class JobsController < ApplicationController

  set_access_control "view_repository" => [:index, :show, :log, :status, :records, :download_file ]
  set_access_control "create_job" => [:new, :create]
  set_access_control "cancel_job" => [:cancel]

  include ExportHelper

  def index
    respond_to do |format|
      format.html {
        @search_data = Search.for_type(session[:repo_id], "job", params_for_backend_search.merge({"facet[]" => SearchResultData.JOB_FACETS}))
      }
      format.csv {
        search_params = params_for_backend_search.merge({"facet[]" => SearchResultData.JOB_FACETS})
        search_params["type[]"] = "job"
        uri = "/repositories/#{session[:repo_id]}/search"
        csv_response( uri, Search.build_filters(search_params), "#{I18n.t('job._plural').downcase}." )
      }
    end
  end

  def new
    @job = JSONModel(:job).new._always_valid!
    @import_types = import_types
    @report_data = JSONModel::HTTP::get_json("/reports")

    # handle any options passed through via parameters
    @job_type = params['job_type']
  end

  def create
    @job_type = params['job']['job_type']

    job_data = params['job']

    # Knock out the _resolved parameter because it's often very large
    # and clean up the job data to match the schema types.
    job_data = ASUtils.recursive_reject_key(job_data) { |k| k === '_resolved' }
    job_data = cleanup_params_for_schema(job_data, JSONModel(@job_type.intern).schema)

    files = Hash[Array(params['files']).reject(&:blank?).map {|file|
                                  [file.original_filename, file.tempfile]}]

    job_params = ASUtils.recursive_reject_key(params['job']['job_params']) { |k| k === '_resolved' }

    job_data["repo_id"] ||= session[:repo_id]
    begin
      job = Job.new(@job_type, job_data, files,
                                  job_params
                   )
      uploaded = job.upload

      if (params['ajax'])
        if params[:iframePOST] # IE saviour. Render the form in a textarea for the AjaxPost plugin to pick out.
          render :plain => "<textarea data-type='json'>#{uploaded.to_json}</textarea>"
        else
          render :json => uploaded
        end
      else
        redirect_to :action => :show, :id => JSONModel(:job).id_for(uploaded['uri'])
      end

    rescue JSONModel::ValidationException => e
      @exceptions = e.invalid_object._exceptions
      @job = e.invalid_object
      @import_types = import_types
      @report_data = JSONModel::HTTP::get_json("/reports")

      params['job_type'] = @job_type

      render :new, :status => 500

    rescue Exception => e
      Rails.logger.error "An unexpected error occurred while creating a job. Please note the following for support: #{job_data}"
    end
  end


  def current_record
    @job
  end


  def show
    @job = JSONModel(:job).find(params[:id], "resolve[]" => "repository")
    @files = JSONModel::HTTP::get_json("#{@job['uri']}/output_files")
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
      json[:queue_position_message] = job.queue_position === 0 ? t("job._frontend.messages.queue_position_next") : t("job._frontend.messages.queue_position", :position => (job.queue_position+1).ordinalize)
    end

    render :json => json
  end


  def download_file
    @job = JSONModel(:job).find(params[:job_id], "resolve[]" => "repository")

    # this is a hacky solution
    # there should be a better way for jobs to specify file names
    if @job['job_type'] == 'report_job'
      filename_end = "#{@job.job['report_type']}_#{@job['time_submitted'].split[0]}"
    else
      filename_end = "file_#{params[:id].to_s}"
    end

    url = "/repositories/#{JSONModel::repository}/jobs/#{params[:job_id]}/output_files/#{params[:id]}"
    stream_file(url, {:format => download_file_format(@job), :filename => "job_#{params[:job_id].to_s}_#{filename_end}" } )
  end


  def records
    @search_data = Job.records(params[:id], params[:page] || 1)
    render_aspace_partial :partial => "jobs/job_records"
  end

  private

  def download_file_format(job)
    if params[:ext]
      format = params[:ext].delete_prefix('.')
    elsif @job.job.has_key?("format") && !@job.job["format"].blank?
      format = @job.job["format"]
    else
      format = "pdf"
    end
  end

  def selected_page
    [Integer(params[:page] || 1), 1].max
  end


  def import_types
    Job.available_import_types.map {|e| [t("import_job.import_type_#{e['name']}", default: e['name'] ), e['name']]}
  end


  def stream_file(request_uri, params = {})
    filename = params[:filename] ? "#{params[:filename]}.#{params[:format]}" : "ead.pdf"

    respond_to do |format|
      format.html {
        self.response.headers["Content-Type"] = "application/#{params[:format]}" if params[:format]
        self.response.headers["Content-Disposition"] = "attachment; filename=#{filename}"
        self.response.headers['Last-Modified'] = Time.now.ctime.to_s

        self.response_body = Enumerator.new do |y|
          xml_response(request_uri, params) do |chunk, percent|
            y << chunk if !chunk.blank?
          end
        end
      }
    end
  end
end
