class BulkImportController < ApplicationController
  set_access_control "update_resource_record" => [:new, :edit, :create, :update, :rde, :add_children, :publish, :accept_children, :get_file, :load_dos]

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

end
