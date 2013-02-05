class SiteController < ApplicationController
  def index
  end

  def search
    set_search_criteria

    @search_data = JSONModel::HTTP::get_json("/search", @criteria)

    render "search/results"
  end

  def resource
    @resource = JSONModel(:resource).find(params[:id], :repo_id => params[:repo_id])
    @repository = JSONModel(:repository).find(params[:repo_id])

    @breadcrumbs = [
      [@repository['repo_code'], url_for(:controller => :site, :action => :repository, :id => @repository.id), "repository"],
      [@resource.title, "#", "resource"]
    ]
  end

  def archival_object
    @archival_object = JSONModel(:archival_object).find(params[:id], :repo_id => params[:repo_id])
    @resource = JSONModel(:resource).find_by_uri(@archival_object['resource']['ref'], :repo_id => params[:repo_id])
    @repository = JSONModel(:repository).find(params[:repo_id])

    @breadcrumbs = [
      [@repository['repo_code'], url_for(:controller => :site, :action => :repository, :id => @repository.id), "repository"],
      [@resource.title, url_for(:controller => :site, :action => :resource, :id => @resource.id, :repo_id => @repository.id), "resource"],
      [@archival_object.title, "#", "archival_object"]
    ]
  end

  def repository
    set_search_criteria

    @repository = JSONModel(:repository).find(params[:repo_id])

    @breadcrumbs = [
      [@repository['repo_code'], url_for(:controller => :site, :action => :repository, :id => @repository.id), "repository"]
    ]

    @search_data = JSONModel::HTTP::get_json("/repositories/#{@repository.id}/search", @criteria)

    render "search/results"
  end


  private

  def set_search_criteria
    @criteria = {
      :q => params[:q].blank? ? "*" : params[:q],
      :page => params[:page] || 1
    }

    @criteria['type[]'] = Array(params[:type]) if not params[:type].blank?
    @criteria['exclude[]'] = params[:exclude] if not params[:exclude].blank?
  end
end
