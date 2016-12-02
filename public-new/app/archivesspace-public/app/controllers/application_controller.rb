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
  helper_method :get_note



  protect_from_forgery with: :exception

  def archivesspace
    ArchivesSpaceClient.new
  end

end
