require 'memoryleak'

class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :establish_session
  before_filter :assign_repositories

  # Allow overriding of templates via the local folder(s)
  if not ASUtils.find_local_directories.blank?
    ASUtils.find_local_directories.map{|local_dir| File.join(local_dir, 'public', 'views')}.reject { |dir| !Dir.exists?(dir) }.each do |template_override_directory|
      prepend_view_path(template_override_directory)
    end
  end

  rescue_from RecordNotFound, :with => :handle_404
  rescue_from Errno::ECONNREFUSED, :with => :handle_backend_down
  rescue_from ArchivesSpacePublic::SessionGone, :with => :reestablish_session
  rescue_from ArchivesSpacePublic::SessionExpired, :with => :reestablish_session


  def handle_404
    render "errors/404"
  end


  def handle_backend_down
    render "errors/backend_down"
  end


  def establish_session
    Thread.current[:backend_session] = BackendSession.get_active_session
  end

  def reestablish_session
    Thread.current[:backend_session] = nil
    BackendSession.refresh_active_session

    establish_session
    redirect_to request.url
  end

  protected

  def assign_repositories
    @repositories = MemoryLeak::Resources.get(:repository)
  end

  def search_params
    params_for_search = params.select{|k,v| ["page", "q", "type", "sort", "filter_term"].include?(k) and not v.blank?}

    params_for_search["page"] ||= 1

    if params_for_search["type"]
      params_for_search["type[]"] = Array(params_for_search["type"]).reject{|v| v.blank?}
      params_for_search.delete("type")
    end

    if params_for_search["filter_term"]
      params_for_search["filter_term[]"] = Array(params_for_search["filter_term"]).reject{|v| v.blank?}
      params_for_search.delete("filter_term")
    end

    params_for_search
  end

end
