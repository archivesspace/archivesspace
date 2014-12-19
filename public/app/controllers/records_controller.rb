class RecordsController < ApplicationController

  before_filter :get_repository

  def resource
    resource = JSONModel(:resource).find(params[:id], :repo_id => params[:repo_id], "resolve[]" => ["subjects", "container_locations", "digital_object", "linked_agents", "related_accessions"])
    raise RecordNotFound.new if (!resource || !resource.publish)

    @resource = ResourceView.new(resource)
    breadcrumb_title = @resource.finding_aid_filing_title ? @resource.finding_aid_filing_title : @resource.title

    @breadcrumbs = [
      [@repository['repo_code'], url_for(:controller => :search, :action => :repository, :id => @repository.id), "repository"],
      [breadcrumb_title, "#", "resource"]
    ]
  end


  def archival_object
    archival_object = JSONModel(:archival_object).find(params[:id], :repo_id => params[:repo_id], "resolve[]" => ["subjects", "container_locations", "digital_object", "linked_agents"])
    raise RecordNotFound.new if (!archival_object || archival_object.has_unpublished_ancestor || !archival_object.publish)

    @archival_object = ArchivalObjectView.new(archival_object)
    @tree_view = Search.tree_view(@archival_object.uri)


    @breadcrumbs = [
      [@repository['repo_code'], url_for(:controller => :search, :action => :repository, :id => @repository.id), "repository"]
    ]

    @tree_view["path_to_root"].each do |record|
      raise RecordNotFound.new if not record["publish"] == true

      if record["node_type"] === "resource"
        @resource_uri = record['record_uri']
        breadcrumb_title = !record["finding_aid_filing_title"].nil? ? record["finding_aid_filing_title"] : record["title"]
        @breadcrumbs.push([breadcrumb_title, url_for(:controller => :records, :action => :resource, :id => record["id"], :repo_id => @repository.id), "resource"])
      else
        @breadcrumbs.push([record["title"], url_for(:controller => :records, :action => :archival_object, :id => record["id"], :repo_id => @repository.id), "archival_object"])
      end
    end

    @breadcrumbs.push([@archival_object.display_string, "#", "archival_object"])
  end


  def digital_object
    digital_object = JSONModel(:digital_object).find(params[:id], :repo_id => params[:repo_id], "resolve[]" => ["subjects", "linked_instances", "linked_agents"])
    raise RecordNotFound.new if (!digital_object || !digital_object.publish)

    @digital_object = DigitalObjectView.new(digital_object)

    @breadcrumbs = [
      [@repository['repo_code'], url_for(:controller => :search, :action => :repository, :id => @repository.id), "repository"],
      [@digital_object.title, "#", "digital_object"]
    ]
  end

  def digital_object_component
    digital_object_component = JSONModel(:digital_object_component).find(params[:id], :repo_id => params[:repo_id], "resolve[]" => ["subjects", "linked_agents"])
    raise RecordNotFound.new if (!digital_object_component || digital_object_component.has_unpublished_ancestor ||  !digital_object_component.publish)

    @digital_object_component = DigitalObjectView.new(digital_object_component)
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

    @breadcrumbs.push([@digital_object_component.display_string, "#", "digital_object_component"])
  end

  def classification
    @classification = JSONModel(:classification).find(params[:id], :repo_id => params[:repo_id], "resolve[]" => ["subjects", "linked_agents"])
    raise RecordNotFound.new if (!@classification || !@classification.publish)

    @tree_view = Search.tree_view(@classification.uri)

    @breadcrumbs = [
      [@repository['repo_code'], url_for(:controller => :search, :action => :repository, :id => @repository.id), "repository"]
    ]

    @breadcrumbs.push([@classification.title, "#", "classification"])
  end

  def accession
    accession = JSONModel(:accession).find(params[:id], :repo_id => params[:repo_id], "resolve[]" => ["subjects", "linked_agents", "container_locations", "digital_object", "related_resources"])
    raise RecordNotFound.new if (!accession || !accession.publish)

    @accession = AccessionView.new(accession)

    @breadcrumbs = [
      [@repository['repo_code'], url_for(:controller => :search, :action => :repository, :id => @repository.id), "repository"]
    ]

    @breadcrumbs.push([@accession.display_string, "#", "accession"])
  end


  def agent
    agent = JSONModel(params[:agent_type]).find(params[:id], "resolve[]" => ["related_agents"])
    raise RecordNotFound.new if (!agent)

    @agent = AgentRecordView.new(agent)

    render :agent
  end


  def tree
    uri = params.fetch(:uri)

    tree_view = Search.tree_view(uri)

    render :json => tree_view
  end


  private

  def get_repository
    @repository = @repositories.select{|repo| JSONModel(:repository).id_for(repo.uri).to_s === params[:repo_id]}.first
  end

end
