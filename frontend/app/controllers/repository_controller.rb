class RepositoryController < ApplicationController
  def new
    render :layout=>nil
  end
  
  def create
    response = Repository.create(params)    
    redirect_to :root
  end
  
  def select
    session[:repo] = params[:repo_id]
    render :text=>"Repository Selected"
  end
end
