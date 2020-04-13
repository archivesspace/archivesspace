class BulkImportController < ApplicationController
  set_access_control "update_resource_record" => [:new, :edit, :create, :update, :rde, :add_children, :publish, :accept_children, :submit_file, :get_file, :load_dos, :link_top_containers_to_archival_objects]

  # create the file form for the spreadsheet
  def get_file
    rid = params[:rid]
    type = params[:type]
    aoid = params[:aoid] || ''
    ref_id = params[:ref_id] || ''
    resource = params[:resource]
    position = params[:position] || '1'
    @resource = Resource.find(params[:rid])
    repo_id = @resource['repository']['ref'].split('/').last
    return render_aspace_partial :partial => "resources/bulk_import_form",  :locals => {:rid => rid, :aoid => aoid, :type => type, :ref_id => ref_id, :resource => resource, :position => position, :repo_id => repo_id} 
  end
  # submit the file to the backend 
  def submit_file
    url = "/bulkimport/ssload"
    file = params.fetch("file")
    newfile = UploadIO.new(file.tempfile, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", file.original_filename)
    params.delete("file")
    params[:filename] = file.original_filename
    params[:filepath]  = newfile.local_path
    response = JSONModel::HTTP.post_form(url, params, :multipart_form_data)
    # change this when we get to diffing between errors and success?
    return render_aspace_partial :partial => "resources/bulk_import_response", :locals => {:data => response.body }
  end
  
  # Link the Top Containers to the Archival Objects 
    def link_top_containers_to_archival_objects
      url = "/bulkimport/linktopcontainers"
      file = params.fetch("file")
      newfile = UploadIO.new(file.tempfile, file.content_type, file.original_filename)
      params.delete("file")
      params[:filename] = file.original_filename
      params[:filepath]  = newfile.local_path
      params[:content_type] = file.content_type
      response = JSONModel::HTTP.post_form(url, params, :multipart_form_data)
      # change this when we get to diffing between errors and success?
      return render_aspace_partial :partial => "resources/bulk_import_response", :locals => {:data => response.body }
    end
end