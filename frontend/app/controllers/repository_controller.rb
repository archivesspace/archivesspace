class RepositoryController < ApplicationController

  def new
    @repository = JSONModel(:repository).new({})
    render :layout=>nil
  end

  def create
    begin
      @repository = JSONModel(:repository).from_hash(params['repository'])
      @repository.save
      render :text=>"Success"
    rescue JSONModel::ValidationException => e
      @repository = e.invalid_object
      @errors = e.errors
      return render action: "new", :layout=>nil
    end
  end
  
  def select    
    session[:repo] = params[:id]
    session[:repo_id] = JSONModel(:repository).find(params[:id]).repo_id
    render :partial=>'shared/header_repository'
  end
  
end
