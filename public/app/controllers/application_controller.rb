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
    # we may have an id param. If so, use it. Short circuit processing to come.
    if params[:id]
      true # do nothing

    # if we have 'slug' strings that are integers, treat them like IDs.
    elsif params[:slug_or_id].match(/^(\d)+$/)
      params[:id] = params[:slug_or_id]

      if params[:repo_slug] && params[:repo_slug].match(/^(\d)+$/)
        params[:rid] = params[:repo_slug]
      end

    # if it looks like a slug, send it to the backend to resolve ids.
    else
      # use repo scoping, if turned on.
      if AppConfig[:repo_name_in_slugs] && repo_scoped_controller?(params[:controller])
        params = resolve_ids_with_repo_scoped_slugs(params)

      # dont use repo scopping
      else
        params = resolve_ids_with_slugs(params)
      end

    end

    update_params!
    return params
  end

  private

    def repo_scoped_controller?(controller_name)
      controller_name == "resources" || "objects" || "accessions" || "classifications"
    end

    def resolve_ids_with_repo_scoped_slugs(params)
      uri = "/slug_with_repo?slug=#{params[:slug_or_id]}&controller=#{params[:controller]}&action=#{params[:action]}&repo_slug=#{params[:repo_slug]}"

      json_response = send_slug_request(uri)
      update_params_from_response!(params, json_response)

      return params
    end

    def resolve_ids_with_slugs(params)
      # look up slug value via HTTP request to backend to find actual id
      uri = "/slug?slug=#{params[:slug_or_id]}&controller=#{params[:controller]}&action=#{params[:action]}"

      json_response = send_slug_request(uri)
      update_params_from_response!(params, json_response)

      return params
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

    def update_params_from_response!(params, json_response)
      #this is what we came here for!
      params[:id] = json_response["id"]
      params[:rid] = json_response["repo_id"] if json_response["repo_id"]

      if params[:controller] == "agents"
        case json_response["table"]
        when "agent_person"
          params[:eid] = "people"
        when "agent_family"
          params[:eid] = "families"
        when "agent_corporate_entity"
          params[:eid] = "corporate_entities"
        when "agent_software"
          params[:eid] = "software"
        end
      end
    end

    def update_params!
      #Add in additional params as needed, based on the controller
      if params[:controller] == "objects"
        params[:obj_type] = "digital_objects"
      end
    end

end
