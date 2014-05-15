class RecordsController < ApplicationController

  before_filter :get_repository

  def resource
    resource = JSONModel(:resource).find(params[:id], :repo_id => params[:repo_id], "resolve[]" => ["subjects", "container_locations", "digital_object", "linked_agents", "related_accessions"])
    raise RecordNotFound.new if (!resource || !resource.publish)

    @resource = ResourceView.new(resource)

    @breadcrumbs = [
      [@repository['repo_code'], url_for(:controller => :search, :action => :repository, :id => @repository.id), "repository"],
      [@resource.finding_aid_status === 'completed' ? @resource.finding_aid_title : @resource.title, "#", "resource"]
    ]
  end

  def resource_by_format
    backend_target = case params[:format]
    when "ead"
      "/repositories/#{params[:repo_id]}/resource_descriptions/#{params[:id]}.xml?include_unpublished=false&include_daos=true&numbered_cs=true"
    when "marc21"
      "/repositories/#{params[:repo_id]}/resources/marc21/#{params[:id]}.xml"
    else
      raise RecordNotFound.new
    end

    raw_response backend_target
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
        @breadcrumbs.push([record["finding_aid_status"] === 'completed' ? record["finding_aid_title"] : record["title"], url_for(:controller => :records, :action => :resource, :id => record["id"], :repo_id => @repository.id), "resource"])
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

  def digital_object_by_format
    backend_target = case params[:format]
    when "dc"
      "/repositories/#{params[:repo_id]}/digital_objects/dublin_core/#{params[:id]}.xml"
    when "mets"
      "/repositories/#{params[:repo_id]}/digital_objects/mets/#{params[:id]}.xml"
    when "mods"
      "/repositories/#{params[:repo_id]}/digital_objects/mods/#{params[:id]}.xml"
    else
      raise RecordNotFound.new
    end

    raw_response backend_target
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

  def raw_response(backend_target)
    if AppConfig[:enable_public_metadata_formats]
      uri      = URI.parse AppConfig[:backend_url]
      http     = Net::HTTP.new uri.host, uri.port
      request  = Net::HTTP::Get.new backend_target
      request['X-ArchivesSpace-Session'] = JSONModel::HTTP.current_backend_session
      response = http.request request
      if response.code == "200"
        render :text => response.body, :content_type => "text/xml"
      else
        raise RecordNotFound.new
      end
    else
      render :inline => '<%= I18n.t("errors.error_403_message") %>'
    end
  end

end
