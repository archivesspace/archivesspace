class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def archivesspace
    ArchivesSpaceClient.new
  end

end
