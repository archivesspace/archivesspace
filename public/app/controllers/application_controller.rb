class ApplicationController < ActionController::Base
  include ManipulateNode
  helper_method :process_mixed_content
  helper_method :strip_mixed_content
  helper_method :inheritance

  include HandleFaceting
  helper_method :get_pretty_facet_value
  helper_method :fetch_only_facets
  helper_method :strip_facets

  include Searchable
  helper_method :set_up_search
  helper_method :process_search_results
  helper_method :handle_results
  helper_method :process_results

  include JsonHelper
  helper_method :process_json_notes

  protect_from_forgery with: :exception

  rescue_from LoginFailedException, :with => :render_backend_failure
  rescue_from RequestFailedException, :with => :render_backend_failure
  rescue_from NoResultsError, :with => :render_no_results_found


  # Allow overriding of templates via the local folder(s)
  if not ASUtils.find_local_directories.blank?
    ASUtils.find_local_directories.map{|local_dir| File.join(local_dir, 'public', 'views')}.reject { |dir| !Dir.exist?(dir) }.each do |template_override_directory|
      prepend_view_path(template_override_directory)
    end
  end

  ArchivesSpaceClient.init

  def archivesspace
    ArchivesSpaceClient.instance
  end

  private

  def render_backend_failure(exception)
    Rails.logger.error(exception)
    render :template => '/error/backend_request_failure', :status => 500
  end

  def render_no_results_found(exception)
    Rails.logger.error(exception)
    flash[:error] = I18n.t('search_results.no_results')
    unless controller_name == 'repositories'
      redirect_back(fallback_location: '/') and return
    else
      redirect_to('/')
    end
  end

  def process_slug_or_id(params)
    # if we have a string that looks like an integer, treat it as an ID.

    # we may have an id param. If so, use it.
    if params[:id]
      true # do nothing
    elsif params[:slug_or_id].match(/^(\d)+$/)
      # id found
      params[:id] = params[:slug_or_id]
    else
      # look up slug value via HTTP request to backend to find actual id
      uri = "/slug?slug=#{params[:slug_or_id]}&controller=#{params[:controller]}&action=#{params[:action]}"

      url = URI("#{JSONModel::HTTP.backend_url}#{uri}")
      response = JSONModel::HTTP.get_response(url)

      json_response = JSON.parse(response.body)

      params[:id] = json_response["id"]
      params[:rid] = json_response["repo_id"] if json_response["repo_id"]

      #additional params
      if params[:controller] == "objects"
        params[:obj_type] = "digital_objects"
      end
    end

  end

end
