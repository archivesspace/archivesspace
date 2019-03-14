class JobsController < ApplicationController

  set_access_control "view_repository" => [:index, :show, :log, :status, :records, :download_file ]
  set_access_control "create_job" => [:new, :create, :create_import_job]
  set_access_control "cancel_job" => [:cancel]
  
  include ExportHelper

  def index
    @active_jobs = Job.active
    @search_data = Job.archived(selected_page)
    @files = {}
    (@active_jobs + @search_data['results']).each do |job|
      @files[job['uri']] = []
      files = JSONModel::HTTP::get_json("#{job['uri']}/output_files")
      files.each do |file|
        job_id = job['uri'].split('/').last
        @files[job['uri']].push("/jobs/#{job_id}/file/#{file}")
      end
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
          render :text => "<textarea data-type='json'>#{uploaded.to_json}</textarea>"
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
    end

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
      json[:queue_position_message] = job.queue_position === 0 ? I18n.t("job._frontend.messages.queue_position_next") : I18n.t("job._frontend.messages.queue_position", :position => (job.queue_position+1).ordinalize)
    end

    render :json => json
  end


  def download_file
    @job = JSONModel(:job).find(params[:job_id], "resolve[]" => "repository")
    
    if @job.job.has_key?("format") && !@job.job["format"].blank? 
        format = @job.job["format"]
    else
        format = "pdf"
    end

    # this is a hacky solution
    # there should be a better way for jobs to specify file names
    if @job['job_type'] == 'report_job'
      filename_end = "#{@job.job['report_type']}_#{@job['time_submitted'].split[0]}"
    else
      filename_end = "file_#{params[:id].to_s}"
    end

    url = "/repositories/#{JSONModel::repository}/jobs/#{params[:job_id]}/output_files/#{params[:id]}"
    stream_file(url, {:format => format, :filename => "job_#{params[:job_id].to_s}_#{filename_end}" } ) 
  end
  
  
  def records
    @search_data = Job.records(params[:id], params[:page] || 1)
    render_aspace_partial :partial => "jobs/job_records"
  end

  private

  def selected_page
    [Integer(params[:page] || 1), 1].max
  end


  def import_types
    Job.available_import_types.map {|e| [I18n.t("import_job.import_type_#{e['name']}", default: e['name'] ), e['name']]}
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
