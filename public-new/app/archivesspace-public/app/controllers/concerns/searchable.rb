module Searchable
  extend ActiveSupport::Concern
# also sets up searches, handles search results.  
# TODO: refactor processing
  def set_up_search(default_types = [],default_facets=[],default_search_opts={}, params={}, q='')
    limit = params.fetch(:limit,'')
    field = params.fetch(:field, nil)
    if !limit.blank?
      default_types = [limit]
    end
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
      pq = params.fetch(:q, '*').strip
      pq = '*' if pq.blank?
      @query += "#{field}:" if !field.blank?
      @query += pq
      @base_search = "#{@base_search}q=#{@query}"
    end
    res_id = params.fetch(:res_id, '')
    repo_id = params.fetch(:repo_id, '')
    if !res_id.blank?
      @query = @query != '*' ? "#{@query} AND " : ''
      @query += "resource:\"#{res_id}\""
      @base_search = "#{@base_search}&res_id=#{res_id.gsub('/','%2f')}"
    elsif !repo_id.blank?
      @query = @query != '*' ? "#{@query} AND " : ''
      @query +=  "repository:\"#{repo_id}\""
      @base_search = "#{@base_search}&repo_id=#{repo_id.gsub('/','%2f')}"
    end
    years = get_years(params)
    if !years.blank?
      @query = "#{@query} AND years:[#{years['from_year']} TO #{years['to_year']}]"
      @base_search = "#{@base_search}&from_year=#{years['from_year']}&to_year=#{years['to_year']}"
    end
    @base_search += "&limit=#{limit}" if !limit.blank?
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


  def set_up_advanced_search(default_types = [],default_facets=[],default_search_opts={}, params={})
    limit = params.fetch(:limit,'')
    if !limit.blank?
      default_types = [limit]
    end

    queries = params.fetch(:q, nil)
    raise I18n.t('navbar.error_no_term') if queries.nil?
    have_query = false
    ops = params.fetch(:op, [])
    fields = params.fetch(:field, [])
    from_years = params.fetch(:from_year, [])
    to_years = params.fetch(:to_year, [])

    advanced_query_builder = AdvancedQueryBuilder.new

    queries.each_with_index { |query, i|
      unless query.blank?
        have_query = true
        op = ops[i]
        field = fields[i].blank? ? 'keyword' : fields[i]
        from = from_years[i]
        to = to_years[i]

        @base_search += '&' if @base_search.last != '?'
        @base_search += "q[]=#{CGI.escape(query)}&op[]=#{CGI.escape(op)}&field[]=#{CGI.escape(field)}&from_year[]=#{CGI.escape(from)}&to_year[]=#{CGI.escape(to)}"

        builder = AdvancedQueryBuilder.new

      # add field part of the row
        builder.and(field, query, 'text', op == 'NOT')

      # add year range part of the row
        unless from.blank? && to.blank?
          builder.and('years', AdvancedQueryBuilder::RangeValue.new(from, to), 'range', op == 'NOT')
        end
        
        # add to the builder based on the op
        if op == 'OR'
          advanced_query_builder.or(builder)
        else
          advanced_query_builder.and(builder)
        end
      end
    }
    if !have_query
      raise I18n.t('navbar.error_no_term')
    end
      
    @criteria = default_search_opts

    @base_search += "&limit=#{limit}" if !limit.blank?

    @facet_filter = FacetFilter.new(default_facets, params.fetch(:filter_fields,[]), params.fetch(:filter_values,[]))
    # building the query for the facetting
    type_query_builder = AdvancedQueryBuilder.new
    default_types.reduce(type_query_builder) {|b, type|
      b.or('types', type)
    }

    @criteria['aq'] = advanced_query_builder.build.to_json
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
#        Pry::ColorPrinter.pp(result['json'])
      end
      result['json']['container_disp'] = container_display(result)
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
      # and yet another kind of convolution
      if result['_resolved_top_container_uri_u_sstr'].kind_of?(Hash)
        rr = result['_resolved_top_container_uri_u_sstr'].shift
        if !rr[1][0]['json'].blank?
          result['_resolved_top_container_uri_u_sstr']['json'] = JSON.parse( rr[1][0]['json'])
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


  def search_terms(params)
    terms = ''
    queries = params.fetch(:q, nil)
    ops = params.fetch(:op, [])
    field = params.fetch(:field, [])
    from_year = params.fetch(:from_year, [])
    to_year = params.fetch(:to_year, [])
    limit = params.fetch(:limit, '')
     queries.each_with_index do |query, i|
      if i == 0
        terms = query
        unless limit.blank?
          limit_term = limit == 'resource'? 'resources' : 'digital'
          terms += ' ' + I18n.t('search-limiting', :limit =>  I18n.t("search-limits.#{limit_term}"))
        end
      else
        terms += ' ' + ops[i] + ' ' + query
      end
      unless field[i].blank?
        field_term = (field[i] == 'creators_text'? I18n.t('search_results.filter.creators') : I18n.t("search_results.filter.#{field[i]}"))
        terms += ' ' + I18n.t('searched-field', :field => field_term)
      end
      unless from_year[i].blank? && to_year[i].blank?
        terms += ' ' + I18n.t('search_results.filter.from_to', 
                       :begin =>(from_year[i].blank? || from_year[i] == '*' ? I18n.t('search_results.filter_year_begin') : from_year[i]), 
                       :end => (to_year[i].blank? || to_year[i] == '*' ? I18n.t('search_results.filter.year_now') : to_year[i]) )
      end
    end
    terms
  end

  private
  def container_display(result)
    display = ""
    json = result['json']
    if !json['instances'].blank? && json['instances'].kind_of?(Array)
      if json['instances'][0].kind_of?(Hash)
        if json['instances'][0]['container'].present? && json['instances'][0]['container'].kind_of?(Hash)
          %w{1 2 3}.each do |i|
            type = process_container_type(json['instances'][0]['container']["type_#{i}"]) 
            if !json['instances'][0]['container']["indicator_#{i}"].blank?
              display += type + ' ' + json['instances'][0]['container']["indicator_#{i}"] + ', '
            end
          end
          display = display.strip.chop  # remove the final comma
        end
      end
    end
    return display
  end
  # have to do this because we don't know the types at the moment
  def process_container_type(in_type)
    type = '' 
    if !in_type.blank?
      type = (in_type == 'unspecified' ?'': in_type)
#      type = 'box' if type == 'boxes'
#      type = type.chomp.chop if type.end_with?('s')
    end
    type
  end


end
