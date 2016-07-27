class RepositoriesController < ApplicationController
  include HandleFaceting
  def index
    @criteria = {}
    # let's not include any 0-colection repositories unless specified
    include_zero = (!params.blank? && params['include_empty']) 
    facets = fetch_facets('types:resource', ['repository'], include_zero)
    facets_ct = 0
    if !facets.blank?
      repos = facets['repository']
      facets_ct = (repos.length / 2)
#      Rails.logger.debug("repos.length: #{repos.length}")
      repos.each_slice(2) do |r, ct|
        facets[r] = ct if (ct > 0 || include_zero )
      end
    else 
      facets = {}
    end
    # ok, page sizing is kind of complicated if not including zero counts
    page_size =  params['page_size'].to_i if !params.blank?
    page_size = 20 if page_size == 0
    include_zero = include_zero || facets_ct == facets.length || facets.length == 0  # don't need to worry about pagination if there are no zero-count repos
    page_size = facets_ct if (!include_zero && facets_ct > page_size) 
    query = 'primary_type:repository'
    page = params['page'] || 1 if !params.blank?
#    @criteria['page_size'] = page_size
    if !include_zero
      query = "id:( #{facets.keys.to_s.gsub(/,/, " OR ").gsub(/\[/, '').gsub(/\]/, '')} )"
    end
    Rails.logger.debug(@criteria.keys)
    @search_data =  archivesspace.search(query, page) || {}
    Rails.logger.debug("TOTAL HITS: #{@search_data['total_hits']}")
    @hits = facets.length
    @json = []
    if !@search_data['results'].blank?
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
    @json.sort_by!{|h| h['display_string'].upcase}
    @page_title = (@json.length > 1 ? I18n.t('repository._plural') : I18n.t('repository._singular')) +  " " + I18n.t('listing') 
    render 
  end

  def show
    facets = fetch_facets("(-primary_type:tree_view AND repository:\"/repositories/#{params[:id]}\")", ['subjects', 'agents','types', 'resource'], true)
    resources = {}
    @subj_ct = 0
    @agent_ct = 0
    @rec_ct = 0
    @collection_ct = 0
    unless facets.blank?
      Rails.logger.debug("subject")
      @subj_ct = strip_facets(facets['subjects'], false).length
      Rails.logger.debug("agent")
      @agent_ct = strip_facets(facets['agents'], false).length
      Rails.logger.debug("resources")
      resources = strip_facets(facets['resource'], true).length
      Rails.logger.debug("types")
      types = strip_facets(facets['types'], false)
      @rec_ct = (types['archival_object'] || 0) + (types['digital_object'] || 0)
    end
    @criteria = {}
    @criteria[:page_size] = 1
    query = "id:\"/repositories/#{params[:id]}\""
    @data =  archivesspace.search(query, 1, @criteria) || {}
    @result
    unless @data['results'].blank?
      @result = JSON.parse(@data['results'][0]['json'])
      @result['count'] = resources
      @page_title = @result['name']
      render 
    end
  end

  private

  # strip out: 0-value facets, facets of form "ead/ arch*"
  # returns a hash with the text of the facet as the key, count as the value
  def strip_facets(facets_array, zero_only)
    facets = {}
    facets_array.each_slice(2) do |t, ct|
      next if ct == 0
      next if (zero_only && t.start_with?("ead/ archdesc/ "))
      facets[t] = ct
      Rails.logger.debug("Score! #{t} #{ct}")
    end
    facets
  end



end
