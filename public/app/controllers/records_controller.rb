class RecordsController < ApplicationController
  include ApplicationHelper  
  before_action :get_repository

  def resource
    resource = JSONModel(:resource).find(params[:id], :repo_id => params[:repo_id], "resolve[]" => ["subjects", "container_locations", "digital_object", "linked_agents", "related_accessions"])
    raise RecordNotFound.new if (!resource || !resource.publish)
    @resource_title = title_or_finding_aid_filing_title(resource)
    @resource = ResourceView.new(resource)

    @breadcrumbs = [
      [@repository['repo_code'], url_for(:controller => :search, :action => :repository, :id => @repository.id), "repository"],
      [@resource_title, "#", "resource"]
    ]
  end


  def archival_object
    archival_object = JSONModel(:archival_object).find(params[:id], :repo_id => params[:repo_id], "resolve[]" => ["subjects", "container_locations", "digital_object", "linked_agents"])
    raise RecordNotFound.new if (!archival_object || archival_object.has_unpublished_ancestor || !archival_object.publish)

    @archival_object = ArchivalObjectView.new(archival_object)

    @breadcrumbs = [
      [@repository['repo_code'], url_for(:controller => :search, :action => :repository, :id => @repository.id), "repository"]
    ]

    @resource_uri = archival_object['resource']['ref']

    node_from_root = Search.get_raw_record(@resource_uri + '/tree/node_from_root_' + @archival_object.id.to_s)
    ASUtils.wrap(node_from_root.fetch(@archival_object.id.to_s)).each do |node|
      if node['node']
        @breadcrumbs.push([node['title'], "#{AppConfig[:public_proxy_prefix]}#{node['node']}".gsub('//', '/'), 'archival_object'])
      else
        resource_uri = node['root_record_uri']
        resource_id = JSONModel.parse_reference(resource_uri).fetch(:id)
        resource = JSONModel(:resource).find(resource_id, :repo_id => params[:repo_id])
        @resource_title = title_or_finding_aid_filing_title(resource)
        @breadcrumbs.push([@resource_title, "#{AppConfig[:public_proxy_prefix]}#{node['root_record_uri']}".gsub('//', '/'), 'resource'])
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
    # @tree_view = Search.tree_view(@digital_object_component.uri)

    @breadcrumbs = [
      [@repository['repo_code'], url_for(:controller => :search, :action => :repository, :id => @repository.id), "repository"]
    ]

    @digital_object_uri = digital_object_component['digital_object']['ref']

    node_from_root = Search.get_raw_record(@digital_object_uri + '/tree/node_from_root_' + @digital_object_component.id.to_s)
    ASUtils.wrap(node_from_root.fetch(@digital_object_component.id.to_s)).each do |node|
      if node['node']
        @breadcrumbs.push([node['title'], "#{AppConfig[:public_proxy_prefix]}#{node['node']}".gsub('//', '/'), 'digital_object_component'])
      else
        @breadcrumbs.push([node['title'], "#{AppConfig[:public_proxy_prefix]}#{node['root_record_uri']}".gsub('//', '/'), 'digital_object'])
      end
    end

    @breadcrumbs.push([@digital_object_component.display_string, "#", "digital_object_component"])
  end

  def classification
    @classification = JSONModel(:classification).find(params[:id], :repo_id => params[:repo_id], "resolve[]" => ["subjects", "linked_agents"])
    raise RecordNotFound.new if (!@classification || !@classification.publish)

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


  def resource_tree_root
    @root_uri = "/repositories/#{params[:repo_id]}/resources/#{params[:id]}"

    render :json => Search.get_raw_record(@root_uri + '/tree/root')
  end

  def resource_tree_node
    @root_uri = "/repositories/#{params[:repo_id]}/resources/#{params[:id]}"

    render :json => Search.get_raw_record(@root_uri + '/tree/node_' + params[:node])
  end


  def resource_tree_node_from_root
    @root_uri = "/repositories/#{params[:repo_id]}/resources/#{params[:id]}"

    render :json => Search.get_raw_record(@root_uri + '/tree/node_from_root_' + params[:node_ids][0])
  end


  def resource_tree_waypoint
    @root_uri = "/repositories/#{params[:repo_id]}/resources/#{params[:id]}"

    render :json => Search.get_raw_record(@root_uri + '/tree/waypoint_' + params[:node] + '_' + params[:offset])
  end


  def digital_object_tree_root
    @root_uri = "/repositories/#{params[:repo_id]}/digital_objects/#{params[:id]}"

    render :json => Search.get_raw_record(@root_uri + '/tree/root')
  end

  def digital_object_tree_node
    @root_uri = "/repositories/#{params[:repo_id]}/digital_objects/#{params[:id]}"

    render :json => Search.get_raw_record(@root_uri + '/tree/node_' + params[:node])
  end


  def digital_object_tree_node_from_root
    @root_uri = "/repositories/#{params[:repo_id]}/digital_objects/#{params[:id]}"

    render :json => Search.get_raw_record(@root_uri + '/tree/node_from_root_' + params[:node_ids][0])
  end


  def digital_object_tree_waypoint
    @root_uri = "/repositories/#{params[:repo_id]}/digital_objects/#{params[:id]}"

    render :json => Search.get_raw_record(@root_uri + '/tree/waypoint_' + params[:node] + '_' + params[:offset])
  end


  def classification_tree_root
    @root_uri = "/repositories/#{params[:repo_id]}/classifications/#{params[:id]}"

    render :json => Search.get_raw_record(@root_uri + '/tree/root')
  end

  def classification_tree_node
    @root_uri = "/repositories/#{params[:repo_id]}/classifications/#{params[:id]}"

    render :json => Search.get_raw_record(@root_uri + '/tree/node_' + params[:node])
  end


  def classification_tree_node_from_root
    @root_uri = "/repositories/#{params[:repo_id]}/classifications/#{params[:id]}"

    render :json => Search.get_raw_record(@root_uri + '/tree/node_from_root_' + params[:node_ids][0])
  end


  def classification_tree_waypoint
    @root_uri = "/repositories/#{params[:repo_id]}/classifications/#{params[:id]}"

    render :json => Search.get_raw_record(@root_uri + '/tree/waypoint_' + params[:node] + '_' + params[:offset])
  end


  def classification_search
    classification = JSONModel(:classification).find(params[:id], :repo_id => params[:repo_id])
    raise RecordNotFound.new if (!classification || !classification.publish)

    url_opts = {
      :controller => :search,
      :action => :search,
      :term_map => {classification.uri => classification.title}.to_json
    }.merge(params_for_search({
                                "add_filter_term" => {
                                  "classification_uri" => classification.uri
                                }.to_json
                              }))

    redirect_to url_for(url_opts)
  end


  def classification_term_search
    classification_term = JSONModel(:classification_term).find(params[:id], :repo_id => params[:repo_id])
    raise RecordNotFound.new if (!classification_term || !classification_term.publish)

    url_opts = {
      :controller => :search,
      :action => :search,
      :term_map => { classification_term.uri => classification_term.title }.to_json
    }.merge(params_for_search({
                                "add_filter_term" => {
                                  "classification_uri" => classification_term.uri
                                }.to_json
                              }))

    redirect_to url_for(url_opts)
  end


  private

  def get_repository
    @repository = @repositories.select{|repo| JSONModel(:repository).id_for(repo.uri).to_s === params[:repo_id]}.first
  end

end
