class RepositoriesController < ApplicationController
  include ResultInfo
  helper_method :process_repo_info
  skip_before_filter  :verify_authenticity_token  

  DEFAULT_SEARCH_FACET_TYPES = ['primary_type', 'subjects', 'agents']
  DEFAULT_REPO_SEARCH_OPTS = {
#    'sort' => 'title_sort asc',
    'resolve[]' => ['repository:id', 'resource:id@compact_resource'],
    'facet.mincount' => 1
  }
  DEFAULT_TYPES =  %w{archival_object digital_object agent resource accession}

  # get all repositories
  # TODO: get this somehow in line with using the Searchable module
  def index
    @criteria = {}
    @criteria['sort'] = "repo_sort asc"  # per James Bullen

    
    # let's not include any 0-colection repositories unless specified
    # include_zero = (!params.blank? && params['include_empty']) 

    # ok, page sizing is kind of complicated if not including zero counts
    page_size =  params['page_size'].to_i if !params.blank?
    page_size = AppConfig[:search_results_page_size] if page_size == 0
    query = 'primary_type:repository'
    facets = find_resource_facet
    page = params['page'] || 1 if !params.blank?
    @criteria['page_size'] = 100
    @search_data =  archivesspace.search(query, page, @criteria) || {}
    Rails.logger.debug("TOTAL HITS: #{@search_data['total_hits']}, last_page: #{@search_data['last_page']}")
    @hits = facets.length
    @json = []
    if !@search_data['results'].blank?
      @pager =  Pager.new("/repositories?", @search_data['this_page'],@search_data['last_page'])
      @search_data['results'].each do |result| 
        hash = JSON.parse(result['json']) || {}
        id = hash['uri']
        if !facets[id].blank?
          hash['count'] = facets[id]
          @json.push(hash)
        end
      end
#      Rails.logger.debug("First hash: #{@json[0]}")
    end
#    @json.sort_by!{|h| h['display_string'].upcase}
    @page_title = (@json.length > 1 ? I18n.t('repository._plural') : I18n.t('repository._singular')) +  " " + I18n.t('listing') 
    render 
  end

  def search
    repo_id = params.require(:rid)
    @base_search = "/repositories/#{repo_id}/search?"
    begin
      # this is temporary unless & until the search respositories endpoint is fixed on the backend
      new_search_opts =  DEFAULT_REPO_SEARCH_OPTS 
      new_search_opts['fq'] = ["repository:\"/repositories/#{repo_id}\""]
     
      set_up_advanced_search(DEFAULT_TYPES, DEFAULT_SEARCH_FACET_TYPES, new_search_opts, params)
#NOTE the redirect back here on error!
    rescue Exception => error
      flash[:error] = error
      redirect_back(fallback_location: "/repositories/#{repo_id}/" ) and return
    end
    page = Integer(params.fetch(:page, "1"))
    @results = archivesspace.advanced_search('/search', page, @criteria)
    if @results['total_hits'].blank? ||  @results['total_hits'] == 0
      flash[:notice] = "#{I18n.t('search_results.no_results')} #{I18n.t('search_results.head_prefix')}"
      redirect_back(fallback_location: @base_search)
    else
      process_search_results(@base_search)
      render
    end 
  end

  def show
    resources = {}
    query = "(id:\"/repositories/#{params[:id]}\" AND publish:true)"
    counts = get_counts("/repositories/#{params[:id]}")
    # Pry::ColorPrinter.pp(counts)
    @subj_ct = counts["subject"] || 0
    @agent_ct = counts["agent"] || 0
    @rec_ct = counts["record"] || 0
    @resource_ct = counts["collection"] || 0
    @group_ct = counts["record_group"] || 0
    sublist_query_base = "publish:true"
    @criteria = {}
    @criteria[:page_size] = 1
    @data =  archivesspace.search(query, 1, @criteria) || {}
    @result
    unless @data['results'].blank?
      @result = JSON.parse(@data['results'][0]['json'])
      # make the repository details easier to get at in the view
      if @result['agent_representation']['_resolved'] && @result['agent_representation']['_resolved']['jsonmodel_type'] == 'agent_corporate_entity'
        @result['repo_info'] = process_repo_info(@result['agent_representation']['_resolved']['agent_contacts'][0])
      end
      @sublist_action = "/repositories/#{params[:id]}/"
      @result['count'] = resources
      @page_title = strip_mixed_content(@result['name'])
      render 
    end
  end

  
  # get the collections, records, subjects or agents of a repository
  # TODO: somehow refactor to use Searchable
  def sublist
    @repo_name = params[:repo] || ''
    @repo_id = "/repositories/#{params[:id]}"
    @type = case params[:type]
             when 'resources'
             'resource'
             when 'subjects'
             'subject'
             when 'agents'
             'agent'
             when 'objects'
             'pui_record'
             when 'groups'
              'pui_record_group'
           end
    @criteria = {}
    @criteria['sort'] = "title_sort asc" 
    page  =  params['page'] || 1 if !params.blank?
    page_size =  params['page_size'].to_i if !params.blank?
    page_size = AppConfig[:search_results_page_size] if page_size == 0
    @criteria[:page_size] = page_size

    if params[:qr].blank? #  && ( @type == 'resource' || @type == 'pui_record' )
      query = compose_sublist_query(@type, params)
    else
      query = params[:qr]
    end
    if @type == 'resource' || @type == 'pui_record'
      resolve_arr = ['repository:id']
      resolve_arr.push 'resource:id@compact_resource'  if @type == 'archival_object'
      @criteria['resolve[]'] = resolve_arr
      @results =  archivesspace.search(query, page, @criteria) || {}
    elsif @type == 'pui_record_group'
      @results= archivesspace.search(query, page, @criteria) || {}
    else
      @criteria[:page] = page
      @criteria['facet[]'] = ['primary_type']
      @results = archivesspace.get_repos_sublist(@repo_id, @type, @criteria) || {}
    end

    Rails.logger.debug("TOTAL HITS: #{@results['total_hits']}, last_page: #{@results['last_page']}")

    if @results['total_hits'] == 0
      flash[:notice] = "#{I18n.t('search_results.no_results')} #{I18n.t('search_results.head_prefix')}"
      redirect_back(fallback_location:  @repo_id)
    else      
      @results['results'].each do |result|
        if !result['json'].blank?
          result['json'] = JSON.parse(result['json']) || {}
        else
          result['json'] = {}
        end
      end
      @type = @type.sub("pui_", "")
      @pager =  Pager.new("/repositories/#{params[:id]}/#{params[:type]}?repo=#{@repo_name}&qr=#{query}", @results['this_page'],@results['last_page'])
      @page_title = (@repo_name != '' ? "#{@repo_name}: " : '') +(@results['results'].length > 1 ? I18n.t("#{@type}._plural") : I18n.t("#{@type}._singular")) +  " " + I18n.t('listing')
    end
  end

  private

  # get counts for repository
  def get_counts(repo_id = nil, collection_only = false)
    if collection_only
      types = ['pui_collection']
    else
      types = ['pui_collection', 'pui_record', 'pui_record_group', 'pui_agent',  'pui_subject']
    end
    # for now, we've got to get the whole enchilada, until we figure out what's wrong
    #  counts = archivesspace.get_types_counts(types, repo_id)
    counts = archivesspace.get_types_counts(types)
    final_counts = {}
    if counts[repo_id]
      counts[repo_id].each do |k, v|
        final_counts[k.sub("pui_",'')] = v
      end
    end
    final_counts
  end


  # get sublist query if it isn't there
  def compose_sublist_query(type, params)
    type_statement = "types:#{type}"
    query =  "(#{type_statement}) "
    query = "#{query} AND publish:true " #if type != 'subject'
    if type == 'subject' || type == 'agent'
      facets = fetch_only_facets("(-primary_type:tree_view AND repository:\"/repositories/#{params[:id]}\")", ["#{type}s"], false)
      unless facets.blank?
        types = strip_facets(facets["#{type}s"], 1)
        query = "#{query} AND #{compose_title_list(types)}"
        Rails.logger.debug("subject or agent  query: #{query}")
      end
    else
      query = "#{query} AND repository:\"/repositories/#{params[:id]}\""
    end
    "( #{query} )"
  end

  def find_resource_facet
    counts = archivesspace.get_types_counts(['pui_collection'])
    facets = {}
    counts.each do |rep, h|
      facets[rep] = h['pui_collection']
    end
    facets
  end

  # compose a string of 'OR'd titles for a query
  def compose_title_list(pairs)
    query = ''
    pairs.each do |s, ct|
      query = query + " title:\"#{s}\""
    end
    "(#{query})"
  end
 

end
