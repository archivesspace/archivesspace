class RepositoryController < ApplicationController

  def new
    @repository = JSONModel(:repository).new._always_valid!
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
    selected = @repositories.find {|r| r.id.to_s == params[:id]}
    session[:repo] = selected.repo_code
    session[:repo_id] = selected.id
    render :partial=>'shared/header_repository', :locals => {:repositories => @repositories}
  end
  
end
