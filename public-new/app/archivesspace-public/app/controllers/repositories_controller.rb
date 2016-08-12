class RepositoriesController < ApplicationController
  include HandleFaceting
  skip_before_filter  :verify_authenticity_token  
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
#    if !include_zero
#      query = "id:( #{facets.keys.to_s.gsub(/,/, " OR ").gsub(/\[/, '').gsub(/\]/, '')} )"
#    end
    @criteria[:page_size] = page_size
    Rails.logger.debug(@criteria.keys)
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

  def show
    resources = {}
    @subj_ct = 0
    @agent_ct = 0
    @rec_ct = 0
    @resource_ct = 0
    query = "(id:\"/repositories/#{params[:id]}\" AND publish:true)"
    sublist_query_base = "publish:true"
    facets = fetch_facets("(-primary_type:tree_view AND repository:\"/repositories/#{params[:id]}\" AND publish:true)", ['subjects', 'agents','types', 'resource'], true)
    unless facets.blank?
      subjs = strip_facets(facets['subjects'], false)
      @subj_ct = subjs.length
      if @subj_ct == 0
        @subj_query = ""
      else
        @subj_query = "(#{sublist_query_base} AND types:subject AND #{compose_title_list(subjs)} )"
      end
      agents = strip_facets(facets['agents'], false) 
      @agent_ct = agents.length
      if @agent_ct == 0
        @agent_query = ""
      else
        @agent_query =  "(#{sublist_query_base} AND types:agent AND  #{compose_title_list(agents)})"
      end
      @resource_ct = strip_facets(facets['resource'], false).length
      types = strip_facets(facets['types'], false)
      @rec_ct = (types['archival_object'] || 0) + (types['digital_object'] || 0)
    end
    @criteria = {}
    @criteria[:page_size] = 1
    @data =  archivesspace.search(query, 1, @criteria) || {}
    @result
    unless @data['results'].blank?
      @result = JSON.parse(@data['results'][0]['json'])
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
    page_size =  params['page_size'].to_i if !params.blank?
    page_size = AppConfig[:search_results_page_size] if page_size == 0
    if params[:qr].blank?
      query = compose_sublist_query(@type, params)
    else
      query = params[:qr]
    end
# right now, this is special to resources & agents
    if @type == 'resource' || @type == 'archival_object'
      resolve_arr = ['repository:id']
      resolve_arr.push 'resource:id@compact_resource' if @type == 'archival_object'
      @criteria['resolve[]'] = resolve_arr
    end
    Rails.logger.debug("sublist query:\n#{query}")
    page = params['page'] || 1 if !params.blank?
    @criteria[:page_size] = page_size
    Rails.logger.debug(@criteria.keys)
    @results =  archivesspace.search(query, page, @criteria) || {}
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
 
  # get sublist query if it isn't there
  def compose_sublist_query(type, params)
    type_statement = "types:#{type =='archival_object' ? 'archival_object OR types:digital_object' : type}"
    Rails.logger.debug("Type: #{type} statement: #{type_statement}")
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
     facets = fetch_facets('types:resource', ['repository'], false) # if we want all repositories, change false to true
    facets_ct = 0
    if !facets.blank?
      repos = facets['repository']
      facets_ct = (repos.length / 2)
#      Rails.logger.debug("repos.length: #{repos.length}")
      repos.each_slice(2) do |r, ct|
        facets[r] = ct   if ct > 0 # we had an 'if (ct >0 || include_zero)'
      end
    else 
      facets = {}
    end
    facets
  end

  # compose a string of 'OR'd titles for a query
  def compose_title_list(pairs)
    query = ''
    pairs.each do |s, ct|
      next if ct == 0
      if query.length > 0
        query = query + " OR "
      end
      query = query + "title:\"#{s}\""
    end
    "(#{query})"
  end
 

end
