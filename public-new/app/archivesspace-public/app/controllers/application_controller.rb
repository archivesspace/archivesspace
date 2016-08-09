class ApplicationController < ActionController::Base
  include ManipulateNode
  helper_method :process_mixed_content

  protect_from_forgery with: :exception

  def archivesspace
    ArchivesSpaceClient.new
  end

end
