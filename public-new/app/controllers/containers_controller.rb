class ContainersController < ApplicationController

  def show
    uri = "/repositories/#{params[:rid]}/top_containers/#{params[:id]}"
    begin
      @criteria = {}
      @result =  archivesspace.get_record(uri, @criteria)
      @repo_info = @result.repository_information
      @page_title = "#{I18n.t('top_container._singular')}: #{strip_mixed_content(@result.display_string)}"
      @context = [{:uri => @repo_info['top']['uri'], :crumb => @repo_info['top']['name']}, {:uri => nil, :crumb => process_mixed_content(@result.display_string)}]

      # fetch all the objects in this container
      fetch_objects_in_container(uri, params)
    rescue RecordNotFound
      @type = I18n.t('top_container._singular')
      @page_title = I18n.t('errors.error_404', :type => @type)
      @uri = uri
      @back_url = request.referer || ''
      render  'shared/not_found', :status => 404
    end
  end

  private

  def fetch_objects_in_container(uri, params)
    qry = "top_container_uri_u_sstr:\"#{uri}\""
    @base_search = "#{uri}?"
    search_opts =  default_search_opts({
                                         'sort' => 'display_string asc',
                                         'facet.mincount' => 1
                                       })
    search_opts['fq']=[qry]
    search_opts['resolve[]']  = ['repository:id', 'resource:id@compact_resource', 'ancestors:id@compact_resource', 'top_container_uri_u_sstr:id']
    set_up_search(['pui_collection', 'pui_archival_object', 'pui_accession'], ['primary_type', 'child_container_u_sstr', 'grand_child_container_u_sstr', 'instance_type_enum_s'], search_opts, params, qry)
    @base_search= @base_search.sub("q=#{qry}", '')
    page = Integer(params.fetch(:page, "1"))

    @results = archivesspace.search(@query, page, @criteria)

    if @results['total_hits'] > 0
      process_search_results(@base_search)
    else
      @results = []
    end
  end

end