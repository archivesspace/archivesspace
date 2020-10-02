class BulkImportController < ApplicationController
  set_access_control "update_resource_record" => [:new, :edit, :create, :update, :rde, :add_children, :publish, :accept_children, :get_file, :load_dos, :link_top_containers_to_archival_objects]

  include ApplicationHelper
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
  # Link the Top Containers to the Archival Objects 
#      def link_top_containers_to_archival_objects
#        url = "/bulkimport/linktopcontainers"
#        files = params.fetch("files")
#        file = files[0]
#        job = params.fetch("job")
#        rid = job['job_params']['rid']
#        repo_id = job['job_params']['repo_id']
#        newfile = UploadIO.new(file.tempfile, file.content_type, file.original_filename)
#        params.delete("files")
#        params.delete("job")
#        params[:rid] = rid
#        params[:repo_id] = repo_id
#        params[:filename] = file.original_filename
#        params[:filepath]  = newfile.local_path
#        params[:filetype] = file.content_type
#        response = JSONModel::HTTP.post_form(url, params.to_h, :multipart_form_data)
#        #If it did not fail, then create a job
#        begin
#          JSON.parse(response.body)
#          #If it isn't a hash then it was successful so create a job
#          files = {file.original_filename => file}
#          job_data = {:jsonmodel_type => 'top_container_linker_job', :filename => params[:filename], :content_type => params[:filetype], :resource_id => rid.to_i, :repo_id => repo_id.to_i, :user => current_user}
#          job = Job.new('top_container_linker_job', job_data, files, nil)
#          uploaded = job.upload
#          joburiarray = uploaded["uri"].split("/")
#          response.body = "Top Container Linker Job with number " + helpers.link_to(joburiarray[4], "/" + joburiarray[3] + "/" + joburiarray[4]) + " created."    
#        rescue JSON::ParserError
#        end
#        return render_aspace_partial :partial => "resources/bulk_import_response", :locals => {:data => response.body }
#      end
end
