class BulkImportController < ApplicationController
  set_access_control "update_resource_record" => [:new, :edit, :create, :update, :rde, :add_children, :publish, :accept_children, :submit_file, :get_file, :load_dos]

  # create the file form for the spreadsheet
  def get_file
    rid = params[:rid]
    type = params[:type]
    aoid = params[:aoid] || ""
    ref_id = params[:ref_id] || ""
    resource = params[:resource]
    position = params[:position] || "1"
    @resource = Resource.find(params[:rid])
    repo_id = @resource["repository"]["ref"].split("/").last
    return render_aspace_partial :partial => "resources/bulk_import_form", :locals => { :rid => rid, :aoid => aoid, :type => type, :ref_id => ref_id, :resource => resource, :position => position, :repo_id => repo_id }
  end

  # create and submit a job
  def submit_file
    file = params.fetch("file")
    rid = params.fetch("rid")
    repo_id = params.fetch("repo_id")
    type = params[:type]
    aoid = params[:aoid] || ""
    ref_id = params[:ref_id] || ""
    position = params[:position] || "1"
    type = params[:type]
    digital_load = params[:digital_load]
    files = { file.original_filename => file }
    job_data = { :jsonmodel_type => "bulk_import_job", :filename => file.original_filename, :content_type => params[:file_type], :resource_id => rid.to_i, :repo_id => repo_id.to_i, :rid => rid, :aoid => aoid, :ref_id => ref_id, :position => position, :type => type, :digital_load => digital_load }
    job = Job.new("bulk_import_job", job_data, files, nil)
    Rails.logger.error("JOB? #{job.pretty_inspect}")
    uploaded = job.upload
    Rails.logger.error("uploaded? #{uploaded.pretty_inspect}")
    joburiarray = uploaded["uri"].split("/")
    response.body = response.body + " Load via SpreadSheet Job with number " + helpers.link_to(joburiarray[4], "/" + joburiarray[3] + "/" + joburiarray[4]) + " created."
  end

  # submit the file to the backend
  def submit_file_old
    url = "/bulkimport/ssload"
    file = params.fetch("file")
    newfile = UploadIO.new(file.tempfile, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", file.original_filename)
    params.delete("file")
    params[:filename] = file.original_filename
    params[:filepath] = newfile.local_path
    response = JSONModel::HTTP.post_form(url, params, :multipart_form_data)
    # change this when we get to diffing between errors and success?
    return render_aspace_partial :partial => "resources/bulk_import_response", :locals => { :data => response.body }
  end
end
