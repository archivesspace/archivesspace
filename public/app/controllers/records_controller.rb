class RecordsController < ApplicationController

  def resource
    @resource = ArchivalObjectView.new(JSONModel(:resource).find(params[:id], :repo_id => params[:repo_id], "resolve[]" => ["subjects", "container_locations", "digital_object", "linked_agents"]))
    raise RecordNotFound.new if not @resource.publish

    @show_components = params[:components].nil? ? true : (params[:components] === 'true')

    @repository = @repositories.select{|repo| JSONModel(:repository).id_for(repo.uri).to_s === params[:repo_id]}.first

    @tree_view = Search.tree_view(@resource.uri)

    load_full_records(@resource.uri, @tree_view['whole_tree'], params[:repo_id])

    @breadcrumbs = [
      [@repository['repo_code'], url_for(:controller => :search, :action => :repository, :id => @repository.id), "repository"],
      [@resource.finding_aid_status === 'completed' ? @resource.finding_aid_title : @resource.title, "#", "resource"]
    ]
  end

  def archival_object
    @archival_object = ArchivalObjectView.new(JSONModel(:archival_object).find(params[:id], :repo_id => params[:repo_id], "resolve[]" => ["subjects", "container_locations", "digital_object", "linked_agents"]))
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


  private

  def fetch_uris(root_uri, repo_id)
    result = {}
    page = 1
    while true
      results = Search.repo(repo_id,
                            {'filter_term[]' => [{'resource' => root_uri}.to_json],
                              'page' => page,
                              'page_size' => AppConfig[:max_page_size].to_i},
                            @repositories)

      results['results'].each do |r|
        rec = ASUtils.json_parse(r['json'])
        result[rec['uri']] = rec
      end

      if results['this_page'] < results['last_page']
        page += 1
      else
        break
      end
    end

    result
  end


  def promise_for(uris_to_lookup, node)
    uris_to_lookup[node['record_uri']] = lambda {|record|
      node['fullrecord'] = record
    }
  end


  def load_full_records(root_uri, tree, repo_id)
    queue = [tree]
    uris_to_lookup = {}
    while !queue.empty?
      node = queue.pop

      # Store a promise to satisfy the record for this URI later on
      if node['record_uri'] && node['record_uri'] != root_uri
        uris_to_lookup[node['record_uri']] = promise_for(uris_to_lookup, node)
      end

      if node['children']
        queue = queue.concat(node['children'])
      end
    end

    records = fetch_uris(root_uri, repo_id)

    uris_to_lookup.each do |uri, callback|
      callback.call(records.fetch(uri))
    end
  end

end
