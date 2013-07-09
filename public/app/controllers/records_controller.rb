class RecordsController < ApplicationController

  before_filter :get_repository

  def resource
    resource = JSONModel(:resource).find(params[:id], :repo_id => params[:repo_id], "resolve[]" => ["subjects", "container_locations", "digital_object", "linked_agents", "related_accessions"])
    raise RecordNotFound.new if (!resource || !resource.publish)

    @resource = ResourceView.new(resource)
    @tree_view = Search.tree_view(@resource.uri)

    load_full_records(@resource.uri, @tree_view['whole_tree'], params[:repo_id])

    @breadcrumbs = [
      [@repository['repo_code'], url_for(:controller => :search, :action => :repository, :id => @repository.id), "repository"],
      [@resource.finding_aid_status === 'completed' ? @resource.finding_aid_title : @resource.title, "#", "resource"]
    ]
  end


  def archival_object
    archival_object = JSONModel(:archival_object).find(params[:id], :repo_id => params[:repo_id], "resolve[]" => ["subjects", "container_locations", "digital_object", "linked_agents"])
    raise RecordNotFound.new if (!archival_object || !archival_object.publish)

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

    @breadcrumbs.push([@archival_object.title, "#", "archival_object"])


    uris_to_fetch = {}
    @tree_view['direct_children'].map{|child_node|
      uris_to_fetch[child_node['record_uri']] = promise_for(child_node)
    }
    fetch_uris(@resource_uri, params[:repo_id], uris_to_fetch)
  end

  def digital_object
    digital_object = JSONModel(:digital_object).find(params[:id], :repo_id => params[:repo_id], "resolve[]" => ["subjects", "linked_instances", "linked_agents"])
    raise RecordNotFound.new if (!digital_object || !digital_object.publish)

    @digital_object = DigitalObjectView.new(digital_object)
    @tree_view = Search.tree_view(@digital_object.uri)

    @breadcrumbs = [
      [@repository['repo_code'], url_for(:controller => :search, :action => :repository, :id => @repository.id), "repository"],
      [@digital_object.title, "#", "digital_object"]
    ]
  end

  def digital_object_component
    digital_object_component = JSONModel(:digital_object_component).find(params[:id], :repo_id => params[:repo_id], "resolve[]" => ["subjects", "linked_agents"])
    raise RecordNotFound.new if (!digital_object_component || !digital_object_component.publish)

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

    @breadcrumbs.push([@accession.title, "#", "accession"])
  end


  private

  def get_repository
    @repository = @repositories.select{|repo| JSONModel(:repository).id_for(repo.uri).to_s === params[:repo_id]}.first
  end


  def fetch_uris(root_uri, repo_id, promises)
    page = 1
    while true
      results = Search.repo(repo_id,
                            {'filter_term[]' => [{'resource' => root_uri}.to_json],
                              'page' => page,
                              'page_size' => AppConfig[:max_page_size].to_i},
                            @repositories)

      results['results'].each do |r|
        rec = ASUtils.json_parse(r['json'])
        begin
          promises.fetch(rec['uri']).call(rec)
        rescue KeyError
        end
      end

      if results['this_page'] < results['last_page']
        page += 1
      else
        break
      end
    end
  end


  def promise_for(node)
    lambda {|record| node['fullrecord'] = record }
  end


  def load_full_records(root_uri, tree, repo_id)
    queue = [tree]
    uris_to_lookup = {}
    while !queue.empty?
      node = queue.pop

      # Store a promise to satisfy the record for this URI later on
      if node['record_uri'] && node['record_uri'] != root_uri
        uris_to_lookup[node['record_uri']] = promise_for(node)
      end

      if node['children']
        queue = queue.concat(node['children'])
      end
    end

    fetch_uris(root_uri, repo_id, uris_to_lookup)
  end

end
