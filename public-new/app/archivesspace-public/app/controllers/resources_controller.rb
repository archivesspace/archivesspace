class ResourcesController <  ApplicationController
  include RepoInfo
  helper_method :process_repo_info

  include TreeApis

  skip_before_filter  :verify_authenticity_token


  DEFAULT_RES_FACET_TYPES = %w{primary_type subjects agents}
  
  DEFAULT_RES_INDEX_OPTS = {
    'sort' => 'title_sort asc',
    'resolve[]' => ['repository:id',  'resource:id@compact_resource'],
    'facet.mincount' => 1
  }

  DEFAULT_RES_SEARCH_OPTS = {
    'resolve[]' => ['repository:id',  'resource:id@compact_resource'],
    'facet.mincount' => 1
  }

  DEFAULT_RES_TYPES = %w{archival_object digital_object agent subject}

  # present a list of resources.  If no repository named, just get all of them.
  def index
    @repo_name = params[:repo] || ""
    query = 'publish:true'
    @base_search = '/repositories'
    if !params.fetch(:rid,'').blank?
      @repo_id = "/repositories/#{params[:rid]}"
      query = "repository:\"#{@repo_id}\" AND #{query}"
      @base_search += "/#{params.fetch(:rid)}"
    end
    @base_search += '/resources?'

    set_up_search(['resource'], [],DEFAULT_RES_INDEX_OPTS, params, query)
    page = Integer(params.fetch(:page, "1"))
#    Rails.logger.debug("Criteria: #{@criteria}")
    @results =  archivesspace.search(@query, page, @criteria) || {}
    
    if @results['total_hits'].blank? ||  @results['total_hits'] == 0
      flash[:notice] = "#{I18n.t('search_results.no_results')} #{I18n.t('search_results.head_prefix')}"
      redirect_back(fallback_location: "/")
    else
      process_search_results(@base_search)
      render
    end
  end

  def search 
    repo_id = params.require(:repo_id)
    res_id = "/repositories/#{repo_id}/resources/#{params.require(:id)}"
    params[:res_id] = res_id
    q = params.fetch(:q,'')
    @base_search = "#{res_id}/search?"
    set_up_search(DEFAULT_RES_TYPES, DEFAULT_RES_FACET_TYPES, DEFAULT_RES_SEARCH_OPTS, params,q)

    page = Integer(params.fetch(:page, "1"))
    @results = archivesspace.search(@query,page, @criteria)
    if @results['total_hits'].blank? ||  @results['total_hits'] == 0
      flash[:notice] = "#{I18n.t('search_results.no_results')} #{I18n.t('search_results.head_prefix')}" 
      redirect_back(fallback_location: @base_search)
    else
      process_search_results(@base_search)
# Pry::ColorPrinter.pp @results['results'][0]['_resolved_resource']['json']
      render
    end
  end
  def show
    uri = "/repositories/#{params[:rid]}/resources/#{params[:id]}"
    record_list = [uri]
    @criteria = {}
    @criteria['resolve[]']  = ['repository:id', 'resource:id@compact_resource']
    @results =  archivesspace.search_records(record_list,1, @criteria) || {}
    @results = handle_results(@results)  # this should process all notes
    if !@results['results'].blank? && @results['results'].length > 0
      @result = @results['results'][0]
      repo = @result['_resolved_repository']['json']
      @repo_info = {}
      unless repo['agent_representation']['_resolved'].blank? || repo['agent_representation']['_resolved']['jsonmodel_type'] != 'agent_corporate_entity'
        @repo_info = process_repo_info(repo['agent_representation']['_resolved']['agent_contacts'][0])
        @repo_info['top'] = {}
        %w(name url parent_institution_name image_url).each do | item |
          @repo_info['top'][item] = repo[item] unless repo[item].blank?
        end
      end

      @agents = process_agents(@result['json']['linked_agents'])
      @subjects = process_subjects(@result['json']['subjects'])
      @finding_aid = process_finding_aid(@result['json'])

      @page_title = "#{I18n.t('resource._singular')}: #{strip_mixed_content(@result['json']['title'])}"
      @context = [{:uri => repo['uri'], :crumb => repo['name']}, {:uri => nil, :crumb => process_mixed_content(@result['json']['title'])}]
      @tree = fetch_tree(uri)
    else
      @page_title = "#{I18n.t('resource._singular')} {I18n.t('errors.error_404')} NOT FOUND"
      @uri = uri
      @back_url = request.referer || ''
      render  'shared/not_found'
    end
  end

  private
  def process_agents(agents_arr)
    agents_h = {}
    agents_arr.each do |agent|
      unless agent['role'].blank? || agent['_resolved'].blank? 
        role = agent['role']
        ag = title_and_uri(agent['_resolved'])
        agents_h[role] = agents_h[role].blank? ? [ag] : agents_h[role].push(ag) if ag
      end
    end
    agents_h
  end

  def process_finding_aid(json)
    fa = {}
    json.keys.each do |k|
      if k.start_with? 'finding_aid'
        fa[k.sub("finding_aid_","")] = strip_mixed_content(json[k])
      elsif k == 'revision_statements'
        revision = []
        v = json[k]
        if v.kind_of? Array
          v.each do |rev|
            revision.push({'date' => rev['date'] || '', 'desc' => rev['description'] || ''})
          end
        else
          if v.kind_of? Hash
            revision.push({'date' => v['date'] || '', 'desc' => v['description'] || ''})
          end
        end
        fa['revision'] = revision
      end
    end
    fa
  end


  def process_subjects(subjects_arr)
    return_arr = []
    subjects_arr.each do |subject|
      unless subject['_resolved'].blank?
        sub = title_and_uri(subject['_resolved'])
        return_arr.push(sub) if sub
      end
    end
    return_arr
  end

  def title_and_uri(in_h)
    if in_h['publish']
      return in_h.slice('uri', 'title')
    else
      return nil
    end
  end

end
