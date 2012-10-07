class RepositoryController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:new, :create, :select]
  before_filter :user_needs_to_be_a_viewer, :only => [:select]
  before_filter :user_needs_to_be_a_manager, :only => [:new, :create]

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
