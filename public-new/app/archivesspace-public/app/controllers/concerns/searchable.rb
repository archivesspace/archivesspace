module Searchable
  extend ActiveSupport::Concern
# also sets up searches, handles search results.  
# TODO: refactor processing
  def set_up_search(default_types = [],default_facets=[],default_search_opts={}, params={}, q='')
    @query = ''
    q = nil if q.strip.blank?
    record_types = params.fetch(:recordtypes, nil)
    if record_types
      record_types.each do |type|
        @query = "primary_type:#{type} #{@query}"
        @base_search += "&recordtypes[]=#{type}"
      end
      @query = "publish:true AND (#{@query})"
      
    elsif q
      @query = q
      @base_search = "#{@base_search}q=#{q}"
    else
      @query = params.fetch(:q, '*')
      @base_search = "#{@base_search}q=#{@query}"
    end
    res_id = params.fetch(:res_id, '')
    repo_id = params.fetch(:repo_id, '')
    if !res_id.blank?
      @query = "resource:\"#{res_id}\" AND #{@query}"
      @base_search = "#{@base_search}&res_id=#{res_id.gsub('/','%2f')}"
    elsif !repo_id.blank?
      @query =  "repository:\"#{repo_id}\" AND #{@query}"
      @base_search = "#{@base_search}&repo_id=#{repo_id.gsub('/','%2f')}"
    end
    years = get_years(params)
    if !years.blank?
      @query = "#{@query} AND years:[#{years['from_year']} TO #{years['to_year']}]"
      @base_search = "#{@base_search}&from_year=#{years['from_year']}&to_year=#{years['to_year']}"
    end
#    Rails.logger.debug("SEARCHABLE BASE: #{@base_search}")
    @criteria = default_search_opts
    @facet_filter = FacetFilter.new(default_facets, params.fetch(:filter_fields,[]), params.fetch(:filter_values,[]))
    # building the query for the facetting
    type_query_builder = AdvancedQueryBuilder.new
    default_types.reduce(type_query_builder) {|b, type|
      b.or('types', type)
    }
    @criteria['filter'] = @facet_filter.get_filter_query.and(type_query_builder).build.to_json
    @criteria['facet[]'] = @facet_filter.get_facet_types
    @criteria['page_size'] = params.fetch(:page_size, AppConfig[:search_results_page_size])
  end

  def get_years(params)
    years = {}
    from = params.fetch(:from_year,'').strip
    to = params.fetch(:to_year,'').strip
    if !from.blank? || !to.blank?
      years['from_year'] = from.blank? ? '*' : from
      years['to_year'] = to.blank? ? '*' : to
    end
    years
  end

  def process_search_results(base="/search")
    @facets = {}
    hits = Integer(@results['total_hits'])
    if !@results['facets'].blank?
      @results['facets']['facet_fields'].keys.each do |type|
        facet_hash = strip_facets( @results['facets']['facet_fields'][type],1, hits)
        if facet_hash.present?
          @facets[type] = facet_hash 
          if type == 'repository'
            @facets['repository'].delete('global')
          end
        end
      end
    end
    @results = handle_results(@results)
    @repo = {}
    if @results['results'].length > 0 && @results['results'][0]['_resolved_repository'].present?
      @repo = @results['results'][0]['_resolved_repository']['json'] || {}
    end
#    q = params.require(:q)
    @page_search = "#{base}#{@facet_filter.get_filter_url_params}"
    @filters = @facet_filter.get_filter_hash
    @pager = Pager.new(@page_search,@results['this_page'],@results['last_page'])
    @page_title = "#{I18n.t('search_results.head_prefix')} #{@results['total_hits']} #{I18n.t('search_results.head_suffix')}"
  end



# process search results in one place, including stripping 0-value facets, and JSON-izing any expected JSON
# if req is not nil, process notes for the type matching the value in req, storing the returned html string in
  #  results['json'}['html'][type]
  def handle_results(results, req = nil, no_zero = true)
    if no_zero && !results['facets'].blank? && !results['facets']['facet_fields'].blank?
      results['facets']['facet_fields'] = strip_facet_fields(results['facets']['facet_fields'])
    end
    results['results'] = process_results(results['results'], req)
    results
  end
  def process_results(results, req = nil)
    results.each do |result|
      if !result['json'].blank?
        result['json'] = JSON.parse(result['json']) || {}
      end
      result['json']['html'] = {}
      if result['json'].has_key?('notes')
        notes_html =  process_json_notes( result['json']['notes'], req)
        notes_html.each do |type, html|
          result['json']['html'][type] = html
        end
      end
      # the info is deeply nested; find & bring it up 
      if result['_resolved_repository'].kind_of?(Hash) 
        rr = result['_resolved_repository'].shift
        if !rr[1][0]['json'].blank?
          result['_resolved_repository']['json'] = JSON.parse( rr[1][0]['json'])
        end
      end
      # A different kind of convolution
      if result['_resolved_resource'].kind_of?(Hash)
        keys  = result['_resolved_resource'].keys
        if keys
          rr = result['_resolved_resource'][keys[0]]
          result['_resolved_resource']['json'] =  rr[0]
        end
      end
    end
    results
  end

# we don't want any 'ead/' or 'archdesc/' stuff
  def strip_facet_fields(facet_fields)
    facet_fields.each do |key, arr|
      facets = {}
      arr.each_slice(2) do |t, ct|
        next if (ct == 0)
        next if t.start_with?("ead/ archdesc/ ")
        facets[t] = ct
      end
      facet_fields[key] = facets
    end
    facet_fields
  end


end
