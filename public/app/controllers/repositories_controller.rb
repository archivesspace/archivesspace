class RepositoriesController < ApplicationController
  include ResultInfo
  helper_method :process_repo_info
  skip_before_action  :verify_authenticity_token

  before_action(:only => [:show, :search]) {
    process_slug_or_id(params)
  }

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
        hash = ASUtils.json_parse(result['json']) || {}
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

  def metadata
    md = {
          '@context' => "http://schema.org/",
          '@type' => 'ArchiveOrganization',
          '@id' => AppConfig[:public_proxy_url] + @result['uri'],
          #this next bit will always be the repo name, not the name associated with the agent record (which is overwritten if the repo record is updated)
          'name' => @result['agent_representation']['_resolved']['display_name']['sort_name'],
          'url' => @result['url'],
          'logo' => @result['image_url'],
          #this next bit will never work since ASpace has a bug with how it enacts its repo-to-agent concept (at least in versions 2.4 and 2.5).... and you can't add an authority ID directly to a repo record.
          'sameAs' => @result['agent_representation']['_resolved']['display_name']['authority_id'],
          'parentOrganization' => {
            '@type' => 'Organization',
            'name' => @result['parent_institution_name']
          }
          # removing contactPoint, since this would need to be on the repo record (along with different contact types... e.g. reference assistance, digitization requests, whatever)
          # 'contactPoint' => @result['agent_representation']['_resolved']['agent_contacts'][0]['name']
        }

    if @result['org_code']
      if @result['country']
        md['identifier'] = @result['country']+'-'+ @result['org_code']
      else
        md['identifier'] = @result['org_code']
      end
    end

    if @result['repo_info']

      md['description'] = @result['repo_info']['top']['description'] if @result['repo_info']['top'] && @result['repo_info']['top']['description']
      md['email'] = @result['repo_info']['email'] if @result['repo_info']['email']

      if @result['repo_info']['telephones']
        md['faxNumber'] = @result['repo_info']['telephones']
          .select{|t| t['number_type'] == 'fax'}
          .map{|f| f['number']}

        md['telephone'] =  @result['repo_info']['telephones']
          .select{|t| t['number_type'] == 'business'}
          .map{|b| b['number']}
      end

      if @result['repo_info']['address']
        md['address'] = {
          '@type' => 'PostalAddress',
          'streetAddress' => @result['repo_info']['address'].join(", "),
          'addressLocality' => @result['repo_info']['city'],
          'addressRegion' => @result['repo_info']['region'],
          'postalCode' => @result['repo_info']['post_code'],
          'addressCountry' => @result['repo_info']['country']
        }
      end
    end

    md.compact
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
    if !@data['results'].blank?
      @result = ASUtils.json_parse(@data['results'][0]['json'])
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

      # i would like to add this to the model, like the rest of the json-ld md mappings, but the repository model is set up quite differently
      # and i'm not sure that i'll update everything as needed if i toy with the repo model in the PUI
      # so, throwing this in the controller for now...
      # but please re-locate and fix!
      # GW: I think its okay here for now, as it would require some re-architecturing the repository show and I dunno if that will break things.
      # @result in the repository view is a hash rather than an object, so it can't access methods in the model
      @metadata = metadata

      render

    else
      record_not_found(uri, 'repository')
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
