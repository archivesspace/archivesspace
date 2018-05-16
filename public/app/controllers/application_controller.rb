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

end
