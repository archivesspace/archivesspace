class IndexController < ApplicationController

  def index
    @repositories = archivesspace.list_repositories
  end

end
