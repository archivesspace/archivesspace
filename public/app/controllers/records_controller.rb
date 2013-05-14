class RecordsController < ApplicationController

  def resource
    @resource = JSONModel(:resource).find(params[:id], :repo_id => params[:repo_id], "resolve[]" => ["subjects", "container_locations", "digital_object", "linked_agents"])
    raise RecordNotFound.new if not @resource.publish

    @repository = @repositories.select{|repo| JSONModel(:repository).id_for(repo.uri).to_s === params[:repo_id]}.first

    @tree_view = Search.tree_view(@resource.uri)

    @breadcrumbs = [
      [@repository['repo_code'], url_for(:controller => :search, :action => :repository, :id => @repository.id), "repository"],
      [@resource.finding_aid_status === 'completed' ? @resource.finding_aid_title : @resource.title, "#", "resource"]
    ]
  end

  def archival_object
    @archival_object = JSONModel(:archival_object).find(params[:id], :repo_id => params[:repo_id], "resolve[]" => ["subjects", "container_locations", "digital_object", "linked_agents"])
    raise RecordNotFound.new if not @archival_object.publish

    @repository = @repositories.select{|repo| JSONModel(:repository).id_for(repo.uri).to_s === params[:repo_id]}.first

    @tree_view = Search.tree_view(@archival_object.uri)

    @breadcrumbs = [
      [@repository['repo_code'], url_for(:controller => :search, :action => :repository, :id => @repository.id), "repository"]
    ]

    @tree_view["path_to_root"].each do |record|
      raise RecordNotFound.new if not record["publish"] == true

      if record["node_type"] === "resource"
        @breadcrumbs.push([record["finding_aid_status"] === 'completed' ? record["finding_aid_title"] : record["title"], url_for(:controller => :records, :action => :resource, :id => record["id"], :repo_id => @repository.id), "resource"])
      else
        @breadcrumbs.push([record["title"], url_for(:controller => :records, :action => :archival_object, :id => record["id"], :repo_id => @repository.id), "archival_object"])
      end
    end

    @breadcrumbs.push([@archival_object.title, "#", "archival_object"])
  end

  def digital_object
    @digital_object = JSONModel(:digital_object).find(params[:id], :repo_id => params[:repo_id], "resolve[]" => ["subjects", "linked_instances", "linked_agents"])
    raise RecordNotFound.new if not @digital_object.publish

    @repository = @repositories.select{|repo| JSONModel(:repository).id_for(repo.uri).to_s === params[:repo_id]}.first

    @tree_view = Search.tree_view(@digital_object.uri)

    @breadcrumbs = [
      [@repository['repo_code'], url_for(:controller => :search, :action => :repository, :id => @repository.id), "repository"],
      [@digital_object.title, "#", "digital_object"]
    ]
  end

  def digital_object_component
    @digital_object_component = JSONModel(:digital_object_component).find(params[:id], :repo_id => params[:repo_id], "resolve[]" => ["subjects", "linked_agents"])
    raise RecordNotFound.new if not @digital_object_component.publish

    @repository = @repositories.select{|repo| JSONModel(:repository).id_for(repo.uri).to_s === params[:repo_id]}.first

    @tree_view = Search.tree_view(@digital_object_component.uri)

    @breadcrumbs = [
      [@repository['repo_code'], url_for(:controller => :search, :action => :repository, :id => @repository.id), "repository"]
    ]

    @tree_view["path_to_root"].each do |record|
      raise RecordNotFound.new if not record["publish"] == true

      if record["node_type"] === "digital_object"
        @breadcrumbs.push([record["title"], url_for(:controller => :records, :action => :digital_object, :id => record["id"], :repo_id => @repository.id), "digital_object"])
      else
        @breadcrumbs.push([record["title"], url_for(:controller => :records, :action => :digital_object_component, :id => record["id"], :repo_id => @repository.id), "digital_object_component"])
      end
    end    

    @breadcrumbs.push([@digital_object_component.title, "#", "digital_object_component"])
  end

end
