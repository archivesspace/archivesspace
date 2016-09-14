class ApplicationController < ActionController::Base
  include ManipulateNode
  helper_method :process_mixed_content
  helper_method :strip_mixed_content

  include HandleFaceting
  helper_method :get_pretty_facet_value
  protect_from_forgery with: :exception

  def archivesspace
    ArchivesSpaceClient.new
  end

end
