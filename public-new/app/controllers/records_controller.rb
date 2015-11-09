class RecordsController < ApplicationController
  before_filter :get_repository


  def resource
    resource = JSONModel(:resource).find(params[:id], :repo_id => params[:repo_id], "resolve[]" => ["subjects", "container_locations", "digital_object", "linked_agents", "related_accessions"])
    raise RecordNotFound.new if (!resource || !resource.publish)


    render :json => resource.to_json
    # breadcrumb_title = title_or_finding_aid_filing_title(resource) 
    # @resource = ResourceView.new(resource)

    # @breadcrumbs = [
    #   [@repository['repo_code'], url_for(:controller => :search, :action => :repository, :id => @repository.id), "repository"],
    #   [breadcrumb_title, "#", "resource"]
    # ]

  end



  def get_repository
    @repository = @repositories.select{|repo| JSONModel(:repository).id_for(repo.uri).to_s === params[:repo_id]}.first
  end
end
