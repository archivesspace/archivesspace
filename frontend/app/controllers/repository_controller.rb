class RepositoryController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:new, :create, :select]
  before_filter(:only => [:select]) {|c| user_must_have("view_repository")}
  before_filter(:only => [:new, :create]) {|c| user_must_have("manage_repository")}

  def new
    @repository = JSONModel(:repository).new._always_valid!
    render :layout => nil
  end

  def create
    handle_crud(:instance => :repository,
                :on_invalid => ->(){ render action: "new", :layout => nil },
                :on_valid => ->(id){
                  MemoryLeak::Resources.refresh(:repository)
                  render :text => "Success"
                })
  end

  def select
    selected = @repositories.find {|r| r.id.to_s == params[:id]}
    session[:repo] = selected.repo_code
    session[:repo_id] = selected.id
    render :text => "Success"
  end

end
