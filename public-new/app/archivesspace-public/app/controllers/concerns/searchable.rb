module Searchable
  extend ActiveSupport::Concern
# also sets up searches, handles search results.  
# TODO: refactor processing
  def set_up_search(default_types = [],default_facets=[],default_search_opts={}, params={}, q='')
    @search = Search.new(params)
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
      @base_search = "#{@base_search}&filter_from_year=#{years['from_year']}&filter_to_year=#{years['to_year']}"
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

  def set_up_and_run_search(default_types = [],default_facets=[],default_search_opts={}, params={})
    set_up_advanced_search(default_types, default_facets, default_search_opts, params)
    page = Integer(params.fetch(:page, "1"))
    @results =  archivesspace.advanced_search('/search', page, @criteria)
    if @results['total_hits'].blank? ||  @results['total_hits'] == 0
      raise  "#{I18n.t('search_results.no_results')} #{I18n.t('search_results.head_prefix')}"
    else
      process_search_results(@base_search)
    end
  end

  def set_up_advanced_search(default_types = [],default_facets=[],default_search_opts={}, params={})
    @search = Search.new(params)
    unless @search[:limit].blank?
      default_types = @search[:limit].split(",")
    end
    set_search_statement
    raise I18n.t('navbar.error_no_term') unless @search.has_query?
    queries = @search[:q]
    have_query = false
    advanced_query_builder = AdvancedQueryBuilder.new
    @search[:q].each_with_index { |query, i|
      query = '*' if query.blank?
      have_query = true
      op = @search[:op][i]
      field = @search[:field][i].blank? ? 'keyword' :  @search[:field][i]
      from = @search[:from_year][i] || ''
      to = @search[:to_year][i] || ''
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
    }
    raise I18n.t('navbar.error_no_term') unless have_query  # just in case we missed something

   # any  search within results? 
    @search[:filter_q].each do |v|
      value = v == '' ? '*' : v
      advanced_query_builder.and('keyword', value, 'text', false)
    end
     # we have to add filtered dates, if they exist
    unless @search[:dates_searched] || (@search[:filter_to_year].blank? && @search[:filter_from_year].blank?)

      from =  @search[:filter_from_year]
      to = @search[:filter_to_year]
      builder = AdvancedQueryBuilder.new
#      builder.and('keyword','*', 'text', false)
      builder.and('years', AdvancedQueryBuilder::RangeValue.new(from, to), 'range', false)
      advanced_query_builder.and(builder)
#      @base_search += "&filter_from_year=#{@search[:filter_from_year]}&filter_to_year=#{@search[:filter_to_year]}"
    end
    @criteria = default_search_opts
    @criteria['sort'] = @search[:sort] if @search[:sort]  # sort can be passed as default or via params
    # we have to pass the sort along in the URL
    @sort =  @criteria['sort']
   Rails.logger.debug("SORT: #{@sort}")
   # if there's an fq passed along...
    unless @criteria['fq'].blank?
      @criteria['fq'].each do |fq |
        f,v = fq.split(":")
        advanced_query_builder.and(f, v, "text", false)
      end
    end

    unless @criteria['repo_id'].blank?
      repo_uri = "/repositories/" + @criteria['repo_id']

      # Add a filter to limit to this repository (or things that link to it)
      this_repo = AdvancedQueryBuilder.new
      this_repo
        .and('repository', repo_uri, 'uri')
        .or('used_within_repository', repo_uri, 'uri')

      advanced_query_builder.and(this_repo)
    end
    advanced_query_builder.and('types', 'pui')
    advanced_query_builder.and('publish', true)
    @base_search += "&limit=#{@search[:limit]}" unless @search[:limit].blank?

    @facet_filter = FacetFilter.new(default_facets, @search[:filter_fields],  @search[:filter_values])

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
    from = params.fetch(:filter_from_year,'').strip
    to = params.fetch(:filter_to_year,'').strip
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
    @page_search = "#{base}#{@facet_filter.get_filter_url_params}#{@search.get_filter_q_params}"
    
    @page_search += "&sort=#{@sort}" if defined?(@sort) && @sort

    @filters = @facet_filter.get_filter_hash(@page_search)

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

  # processes the json portion of the results
  def process_results(results, req = nil)
    results.each do |result|
      if !result['json'].blank?
        result['json'] = JSON.parse(result['json']) || {}
#        Pry::ColorPrinter.pp(result['json'])
      end
      result['json']['display_string'] = full_title(result['json'])
      result['json']['container_disp'] = container_display(result)
      html_notes(result['json'], req)
      # handle dates
      handle_dates( result['json']['dates']) if result['json'].has_key?('dates')
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
#Pry::ColorPrinter.pp result['_resolved_top_container_uri_u_sstr']
        rr = result['_resolved_top_container_uri_u_sstr'].shift
        if !rr[1][0]['json'].blank?
          result['_resolved_top_container_uri_u_sstr']['json'] = JSON.parse( rr[1][0]['json'])
        end
      end
    end
    results
  end

  # handle dates
  def handle_dates(dates)
    dates.each do |date|
      label = date['label'].blank? ? '' : "#{date['label'].titlecase}: "
      label = '' if label == 'Creation: '
      exp =  date['expression'] || ''
      if exp.blank?
        exp = date['begin'] unless date['begin'].blank?
        unless date['end'].blank?
          exp = (exp.blank? ? '' : exp + '-') + date['end']
        end
        Rails.logger.debug("**** NO DATE EXP: #{date}, final exp: #{exp}")
      end
      if date['date_type'] == 'bulk'
        exp = exp.sub('bulk','').sub('()', '').strip
        exp = date['begin'] == date['end'] ? I18n.t('bulk._singular', :dates => exp) :
          I18n.t('bulk._plural', :dates => exp)
      end
      date['final_expression'] = label + exp
    end
  end

  # process notes
  def html_notes(json, req = nil)
    json['html'] = {}
    if json.has_key?('notes')
      notes_html =  process_json_notes(json['notes'], req)
      notes_html.each do |type, html|
        json['html'][type] = html
      end
    end
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
    if queries
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
    end
    terms
  end

  def default_search_opts(default = {})
    opts = {}
    default.each do |k,v|
      opts[k] = v
    end
    opts
  end

  def repo_context(repo_id, type)
    cont = []
    if repo_id
      cont.push({:uri => "/repositories/#{repo_id}", :crumb => get_pretty_facet_value('repository', "/repositories/#{repo_id}")})
      cont.push({:uri => '', :crumb =>  I18n.t("#{type}._plural")})
    end
  end

  private
  
  # creates the html-ized search statement
  def set_search_statement
    rid = defined?(@repo_id) ? @repo_id : nil
#    Pry::ColorPrinter.pp @search
    l = @search[:limit].blank? ? 'all' : @search[:limit]
    type = "<strong> #{I18n.t("search-limits.#{l}")}</strong>"
    type += I18n.t('search_results.in_repository', :name =>  CGI::escapeHTML(get_pretty_facet_value('repository', "/repositories/#{rid}"))) if rid
    
    Rails.logger.debug("TYPE: #{type}")
    condition = " "
    @search[:q].each_with_index do |q,i|
      condition += '<li>' 
      condition += I18n.t("search_results.op.#{@search[:op][i]}").downcase unless i == 0
      f = @search[:field][i].blank? ? 'keyword' : @search[:field][i]
      condition += ' ' + I18n.t("search_results.#{f}_contain", :kw =>  CGI::escapeHTML((q == '*' ? I18n.t('search_results.anything') : q)) )
      unless @search[:from_year][i].blank? &&  @search[:to_year][i].blank?
         from_year = @search[:from_year][i].blank? ? I18n.t('search_results.filter.year_begin') : @search[:from_year][i]
         to_year =  @search[:to_year][i].blank? ? I18n.t('search_results.filter.year_now') : @search[:to_year][i]
        condition += ' ' + I18n.t('search_results.filter.from_to', :begin => "<strong>#{from_year}</strong>", :end => "<strong>#{to_year}</strong>")
      end
      condition += '</li>'
      Rails.logger.debug("Condition: #{condition}")
    end
    @search[:search_statement] = I18n.t('search_results.search_for', :type => type, 
                                        :conditions => "<ul class='no-bullets'>#{condition}</ul>")
  end


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

  # if there's an inherited title, pre-pend it
  def full_title(json)
    ft =  strip_mixed_content(json['display_string'] || json['title'])
    unless json['title_inherited'].blank? || (json['display_string'] || '') == json['title']
      ft = I18n.t('inherited', :title => strip_mixed_content(json['title']), :display => ft)
    end
    ft
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
