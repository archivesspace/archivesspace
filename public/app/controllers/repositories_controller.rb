class RepositoriesController < ApplicationController
  include ResultInfo
  helper_method :process_repo_info
  skip_before_action  :verify_authenticity_token  

  DEFAULT_SEARCH_FACET_TYPES = ['primary_type', 'subjects', 'published_agents']
  DEFAULT_REPO_SEARCH_OPTS = {
     'sort' => 'title_sort asc',
    'resolve[]' => ['repository:id', 'resource:id@compact_resource', 'ancestors:id@compact_resource', 'top_container_uri_u_sstr:id'],
    'facet.mincount' => 1
  }
  DEFAULT_TYPES =  %w{archival_object digital_object agent resource accession}

  # get all repositories
  # TODO: get this somehow in line with using the Searchable module
  def index
    @criteria = {}
    @criteria['sort'] = "repo_sort asc"  # per James Bullen
    # let's not include any 0-collection repositories unless specified
    # include_zero = (!params.blank? && params['include_empty']) 
    # ok, page sizing is kind of complicated if not including zero counts
    page_size =  params['page_size'].to_i if !params.blank?
    page_size = AppConfig[:pui_search_results_page_size] if page_size == 0
    query = 'primary_type:repository'
    facets = find_resource_facet
    page = params['page'] || 1 if !params.blank?
    @criteria['page_size'] = 100
    @search_data =  archivesspace.search(query, page, @criteria) || {}
    Rails.logger.debug("TOTAL HITS: #{@search_data['total_hits']}, last_page: #{@search_data['last_page']}")
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
      Rails.logger.debug("First hash: #{@json[0]}")
    else
      raise NoResultsError.new("No repository records found!")
    end
    @json.sort_by!{|h| h['display_string'].upcase}
    @page_title = I18n.t('list', {:type => (@json.length > 1 ? I18n.t('repository._plural') : I18n.t('repository._singular'))})
    render 
  end

  def search
    @repo_id = params.require(:rid)
    @base_search = "/repositories/#{repo_id}/search?"
    begin
      new_search_opts =  DEFAULT_REPO_SEARCH_OPTS 
      new_search_opts['repo_id'] = @repo_id
      set_up_advanced_search(DEFAULT_TYPES, DEFAULT_SEARCH_FACET_TYPES, new_search_opts, params)
    #   NOTE the redirect back here on error!
    rescue Exception => error
      Rails.logger.debug( error.backtrace ) 
      flash[:error] = I18n.t('errors.unexpected_error')
      redirect_back(fallback_location: "/repositories/#{@repo_id}/" ) and return
    end
    page = Integer(params.fetch(:page, "1"))
    @results = archivesspace.advanced_search('/search', page, @criteria)
    if @results['total_hits'].blank? ||  @results['total_hits'] == 0
      flash[:notice] = I18n.t('search_results.no_results')
      redirect_back(fallback_location: @base_search)
    else
      process_search_results(@base_search)
      Rails.logger.debug("@repo_id: #{@repo_id}")
      render
    end 
  end
  
  def show
    uri = "/repositories/#{params[:id]}"
    resources = {}
    query = "(id:\"#{uri}\" AND publish:true)"
    @counts = get_counts("/repositories/#{params[:id]}")
    @counts['resource'] = @counts['collection']
    @counts['classification'] = @counts['record_group']
    #  Pry::ColorPrinter.pp(counts)
    @criteria = {}
    @criteria[:page_size] = 1
    @data =  archivesspace.search(query, 1, @criteria) || {}
    @result
    if !@data['results'].blank?
      @result = JSON.parse(@data['results'][0]['json'])
      @badges = Repository.badge_list(@result['repo_code'].downcase)
      # Pry::ColorPrinter.pp @badges
      # make the repository details easier to get at in the view
      if @result['agent_representation']['_resolved'] && @result['agent_representation']['_resolved']['jsonmodel_type'] == 'agent_corporate_entity'
        @result['repo_info'] = process_repo_info(@result)
      end
      @sublist_action = "/repositories/#{params[:id]}/"
      @result['count'] = resources
      @page_title = strip_mixed_content(@result['name'])
      @search = Search.new(params)
      render
    else
      @type = I18n.t('repository._singular')
      @page_title = I18n.t('errors.error_404', :type => @type)
      @uri = uri
      @back_url = request.referer || ''
      render  'shared/not_found', :status => 404
    end
  end

  private
  # get counts for repository
  def get_counts(repo_id = nil, collection_only = false)
    if collection_only
      types = ['pui_collection']
    else
      types = %w(pui_collection pui_record pui_record_group pui_accession pui_digital_object pui_agent  pui_subject)
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
