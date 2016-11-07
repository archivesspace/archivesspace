class ObjectsController <  ApplicationController
  include TreeApis
  include RepoInfo
  helper_method :process_repo_info


  skip_before_filter  :verify_authenticity_token

  def show
    uri = "/repositories/#{params[:rid]}/#{params[:obj_type]}/#{params[:id]}"
    @criteria = {}
    @criteria['resolve[]']  = ['repository:id', 'resource:id@compact_resource', 'top_container_uri_u_sstr:id']
    @results =  archivesspace.search_records([uri],1,@criteria)
    @results =  handle_results(@results)
    if !@results['results'].blank? && @results['results'].length > 0
      @result = @results['results'][0]
      @repo_info =  process_repo_info(@result)
      @page_title = strip_mixed_content(@result['json']['display_string'] || @result['json']['title'])
      @tree = fetch_tree(uri)
      @context = get_path(@tree)
      # TODO: This is a monkey patch for digital objects
      if @context.blank?
        @context = []
        unless @result['_resolved_resource'].blank? || @result['_resolved_resource']['json'].blank?
          @context.unshift({:uri => @result['_resolved_resource']['json']['uri'],
                             :crumb => strip_mixed_content(@result['_resolved_resource']['json']['title'])})
        end
      end
      @context.unshift({:uri => @result['_resolved_repository']['json']['uri'], :crumb =>  @result['_resolved_repository']['json']['name']})
      @context.push({:uri => '', :crumb => strip_mixed_content(@result['json']['display_string'] || @result['json']['title']) })
      @prefer_cite = ''
      cite = get_note(@result['json'], 'prefercite')
      unless cite.blank?
        @prefer_cite = strip_mixed_content(cite['note_text'])
      else
        @prefer_cite = "#{@result['json']['title']}." 
        unless @result['_resolved_resource'].blank? || @result['_resolved_resource']['json'].blank?
          @prefer_cite += " #{strip_mixed_content(@result['_resolved_resource']['json']['title'])}."
        end
         unless @repo_info['top']['name'].blank?
           @prefer_cite += " #{ @repo_info['top']['name']}."
        end
      end
      @prefer_cite += "   #{archivesspace.get_full_url(uri)}  #{I18n.t('accessed')} " +  Time.now.strftime("%B %d, %Y") + "."
      Rails.logger.debug("cite: #{@prefer_cite}")


    else
      @page_title = I18n.t 'errors.error_404'
      @uri = uri
      @back_url = request.referer || ''
      render  'shared/not_found'
    end
  end
end
