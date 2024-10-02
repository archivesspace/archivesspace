class ApplicationController < ActionController::Base
  include ManipulateNode
  helper_method :process_mixed_content
  helper_method :process_mixed_content_title
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
  helper_method :repositories_sort_by

  include JsonHelper
  helper_method :process_json_notes

  protect_from_forgery with: :exception

  rescue_from LoginFailedException, :with => :render_backend_failure
  rescue_from RequestFailedException, :with => :render_backend_failure
  rescue_from NoResultsError, :with => :render_no_results_found

  around_action :set_locale


  # Allow overriding of templates via the local folder(s)
  if not ASUtils.find_local_directories.blank?
    ASUtils.find_local_directories.map {|local_dir| File.join(local_dir, 'public', 'views')}.reject { |dir| !Dir.exist?(dir) }.each do |template_override_directory|
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
    # we may have an id param. If so, use it. Short circuit processing to come.
    if params[:id]
      true # do nothing

    # if we have 'slug' strings that are integers, treat them like IDs.
    elsif params[:slug_or_id].match(/^(\d)+$/)
      params[:id] = params[:slug_or_id]

      if params[:repo_slug] && params[:repo_slug].match(/^(\d)+$/)
        params[:rid] = params[:repo_slug]
      end

    # if it looks like a slug, and slugs are enabled, send it to the backend to resolve ids and other params we need.
    elsif AppConfig[:use_human_readable_urls]
      added_params = resolve_ids_with_slugs(params)

      params.merge!(added_params)
    end
  end

  def set_locale(&action)
    if session[:locale]
      locale = session[:locale]
    else
      locale = I18n.default_locale
    end

    I18n.with_locale(locale, &action)
  end

  private

  def resolve_ids_with_slugs(params)
    # look up slug value via HTTP request to backend to find actual id
    uri = "/slug?slug=#{params[:slug_or_id]}&controller=#{params[:controller]}&action=#{params[:action]}"

    json_response = send_slug_request(uri)

    return params_from_response(params, json_response)
  end

  def send_slug_request(uri)
    url = URI("#{JSONModel::HTTP.backend_url}#{uri}")
    response = JSONModel::HTTP.get_response(url)

    if response
      return JSON.parse(response.body)
    else
      return {"id" => -1, "repo_id" => -1}
    end
  end

    # parse response from backend and create a hash of additional params needed to process the request
  def params_from_response(params, json_response)
    added_params = {}

    #this is what we came here for!
    added_params[:id] = json_response["id"]
    added_params[:rid] = json_response["repo_id"] if json_response["repo_id"]

    if params[:controller] == "agents"
      case json_response["table"]
      when "agent_person"
        added_params[:eid] = "people"
      when "agent_family"
        added_params[:eid] = "families"
      when "agent_corporate_entity"
        added_params[:eid] = "corporate_entities"
      when "agent_software"
        added_params[:eid] = "software"
      end
    end

    if params[:controller] == "objects"
      case json_response["table"]
      when "digital_object"
        added_params[:obj_type] = "digital_objects"
      when "archival_object"
        added_params[:obj_type] = "archival_objects"
      when "digital_object_component"
        added_params[:obj_type] = "digital_object_components"
      end
    end

    return added_params
  end

  def record_not_found(uri, type)
    @page_title = I18n.t('errors.error_404', :type => I18n.t("#{type}._singular"))
    @uri = uri
    @back_url = request.referer || ''
    render 'shared/not_found', :status => 404
  end

  def record_not_resolved(uri, type)
    @page_title = I18n.t('errors.error_404', :type => I18n.t("#{type}._singular"))
    @uri = uri
    @back_url = request.referer || ''
    render 'shared/not_found', :status => 404
  end

  def ark_not_resolved(uri)
    @page_title = I18n.t('errors.error_404', :type => 'ARK')
    @uri = uri
    @back_url = request.referer || ''
    render 'shared/not_found', :status => 404
  end
end
