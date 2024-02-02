class WelcomeController < ApplicationController
  set_access_control :public => [:index]

  def index
    info = JSONModel::HTTP::get_json('/')
    view_context.database_warning( info )

    if session[:user] && @repositories.length === 0
      if user_can?('create_repository')
        flash.now[:info] = t("repository._frontend.messages.create_first_repository")
      else
        flash.now[:info] = t("repository._frontend.messages.no_access_to_repositories")
      end
    end
  end
end
