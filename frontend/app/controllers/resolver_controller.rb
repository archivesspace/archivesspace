class ResolverController < ApplicationController

  set_access_control :public => [:resolve_edit, :resolve_readonly]


  def resolve_edit
    if params.has_key? :uri
      resolver = Resolver.new(params[:uri])

      if params.has_key?(:autoselect_repo) && resolver.repository && resolver.repository != session[:repo]
        self.class.session_repo(session, resolver.repository)
        selected = JSONModel(:repository).find(session[:repo_id])
        flash[:success] = t("repository._frontend.messages.changed")
      end
      redirect_to resolver.edit_uri
    else
      unauthorised_access
    end
  end


  def resolve_readonly
    if params.has_key? :uri
      resolver = Resolver.new(params[:uri])

      if params.has_key?(:autoselect_repo) && resolver.repository && resolver.repository != session[:repo]
        self.class.session_repo(session, resolver.repository)
        selected = JSONModel(:repository).find(session[:repo_id])
        flash[:success] = t("repository._frontend.messages.changed")
      end
      redirect_to resolver.view_uri
    else
      unauthorised_access
    end
  end
end
