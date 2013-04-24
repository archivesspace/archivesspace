class WelcomeController < ApplicationController
  skip_before_filter :unauthorised_access

  def index
    if session[:user] && @repositories.length === 0
      if user_can?('create_repository')
        flash.now[:info] = I18n.t("repository._html.messages.create_first_repository")
      else
        flash.now[:info] = I18n.t("repository._html.messages.no_access_to_repositories")
      end
    end
  end
end
