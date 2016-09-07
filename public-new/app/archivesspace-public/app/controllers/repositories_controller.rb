class RepositoriesController < ApplicationController
  include HandleFaceting
  include ProcessResults
  include JsonHelper
  skip_before_filter  :verify_authenticity_token  

  DEFAULT_REPO_SEARCH_OPTS = {
    'types[]' => %w{archival_object digital_object resource accession},
    'sort' => 'title asc',
    'resolve[]' => ['repository:id', 'resource:id@compact_resource'],
    'facet[]' => ['types', 'subjects']
  }
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
    @criteria[:page_size] = page_size
#    Rails.logger.debug(@criteria.keys)
    @search_data =  archivesspace.search(query, page, @criteria) || {}
#    Rails.logger.debug("TOTAL HITS: #{@search_data['total_hits']}, last_page: #{@search_data['last_page']}")
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
    @criteria = DEFAULT_REPO_SEARCH_OPTS
    repo_id = params.require(:rid)
    @criteria['repository'] = repo_id
    @query = params.require(:q)
    @query = "#{@query} AND publish:true"
    page = Integer(params.fetch(:page, "1"))
    @results = archivesspace.search(@query, page, @criteria)
    Rails.logger.debug("Has facets? #{@results['facets']}")
    @results = handle_results(@results)
    @repo = {}
    if @results['results'].length > 0 && @results['results'][0]['_resolved_repository'].present?
      @repo = @results['results'][0]['_resolved_repository']['json'] || {}
    end
    page_search = "/repositories/#{repo_id}/search?q=#{@query}"
    @pager = Pager.new(page_search,@results['this_page'],@results['last_page'])
    @page_title = "#{I18n.t('search_results.head_prefix')} #{@results['total_hits']} #{I18n.t('search_results.head_suffix')}"
    render 
  end

  def show
    resources = {}
    query = "(id:\"/repositories/#{params[:id]}\" AND publish:true)"
    counts = get_counts("/repositories/#{params[:id]}")
    #Pry::ColorPrinter.pp(@counts_results)
    @subj_ct = counts["subject"] || 0
    @agent_ct = counts["person"] || 0
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
        @result['repo_info'] = repo_info(@result['agent_representation']['_resolved']['agent_contacts'][0])
      end
      @sublist_action = "/repositories/#{params[:id]}/"
      @result['count'] = resources
      @page_title = @result['name']
      render 
    end
  end

  

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
             'archival_object'
           end
    @criteria = {}
    @criteria['sort'] = "title asc" 
    page  =  params['page'] || 1 if !params.blank?
    page_size =  params['page_size'].to_i if !params.blank?
    page_size = AppConfig[:search_results_page_size] if page_size == 0
    @criteria[:page_size] = page_size

    if params[:qr].blank? && ( @type == 'resource' || @type == 'archival_object')
      query = compose_sublist_query(@type, params)
    else
      query = params[:qr]
    end
# right now, this is special to resources & agents
    if @type == 'resource' || @type == 'archival_object'
      resolve_arr = ['repository:id']
      resolve_arr.push 'resource:id@compact_resource' if @type == 'archival_object'
      @criteria['resolve[]'] = resolve_arr
      @results =  archivesspace.search(query, page, @criteria) || {}
    else
      @criteria[:page] = page
      @results = archivesspace.get_repos_sublist(@repo_id, @type, @criteria) || {}
    end

    Rails.logger.debug("TOTAL HITS: #{@results['total_hits']}, last_page: #{@results['last_page']}")
    if !@results['results'].blank?
      @results['results'].each do |result|
        if !result['json'].blank?
          result['json'] = JSON.parse(result['json']) || {}
        else
          result['json'] = {}
        end
      end
    end
    @pager =  Pager.new("/repositories/#{params[:id]}/#{params[:type]}?repo=#{@repo_name}&qr=#{query}", @results['this_page'],@results['last_page'])
    @page_title = (@repo_name != '' ? "#{@repo_name}: " : '') +(@results['results'].length > 1 ? I18n.t("#{@type}._plural") : I18n.t("#{@type}._singular")) +  " " + I18n.t('listing')
  end

  private

  # get counts for repository
  def get_counts(repo_id = nil, collection_only = false)
    if collection_only
      types = ['pui_collection']
    else
      types = ['pui_collection', 'pui_record', 'pui_record_group', 'pui_person', 'pui_subject']
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
    type_statement = "types:#{type =='archival_object' ? 'archival_object OR types:digital_object' : type}"
#    Rails.logger.debug("Type: #{type} statement: #{type_statement}")
    query =  "(#{type_statement}) "
    query = "#{query} AND publish:true " if type != 'subject'
    if type == 'subject' || type == 'agent'
      facets = fetch_facets("(-primary_type:tree_view AND repository:\"/repositories/#{params[:id]}\")", ["#{type}s"], false)
      unless facets.blank?
        types = strip_facets(facets["#{type}s"], false)
        query = "#{query} AND #{compose_title_list(types)}"
        Rails.logger.debug("subject or agent  query: #{query}")
      end
    else
      query = "#{query} AND repository:\"/repositories/#{params[:id]}\""
    end
    "( #{query} )"
  end


  # strip out: 0-value facets, facets of form "ead/ arch*"
  # returns a hash with the text of the facet as the key, count as the value
  def strip_facets(facets_array, zero_only)
    facets = {}
    facets_array.each_slice(2) do |t, ct|
      next if (!zero_only && ct == 0)
      next if (zero_only && t.start_with?("ead/ archdesc/ "))
      facets[t] = ct
    end
    facets
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
 
  # extract the repository agent info
  def repo_info(in_h)
    ret_h = {}
    %w{city region post_code country email }.each do |k|
      ret_h[k] = in_h[k] if in_h[k].present?
    end
    if in_h['address_1'].present?
      ret_h['address'] = []
      [1,2,3].each do |i|
        ret_h['address'].push(in_h["address_#{i}"]) if in_h["address_#{i}"].present?
      end
    end
    if in_h['telephones'].present?
      ret_h['telephones'] = []
      in_h['telephones'].each do |tel|
        if tel['number'].present?
          ret_h['telephones'].push(tel['number'])
        end
      end
    end
    ret_h
  end

end
