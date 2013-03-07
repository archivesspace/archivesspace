class RepositoriesController < ApplicationController

  skip_before_filter :unauthorised_access, :only => [:new, :create, :select, :index, :show, :edit, :update]
  before_filter(:only => [:select, :index, :show]) {|c| user_must_have("view_repository")}
  before_filter(:only => [:new, :create, :edit, :update]) {|c| user_must_have("manage_repository")}

  def index
    @search_data = Search.global(search_params.merge({"facet[]" => [], "type[]" => ["repository"]}))
  end

  def new
    @repository = JSONModel(:repository).new._always_valid!
  end

  def create
    handle_crud(:instance => :repository,
                :model => JSONModel(:repository),
                :on_invalid => ->(){
                  return render :partial => "repositories/new" if inline?
                  return render :action => :new
                },
                :on_valid => ->(id){
                  MemoryLeak::Resources.refresh(:repository)

                  return render :json => @repository.to_hash if inline?
            
                  flash[:success] = I18n.t("repository._html.messages.created")
                  return redirect_to :controller => :repositories, :action => :new if params.has_key?(:plus_one)
            
                  redirect_to :controller => :repositories, :action => :show, :id => id
                })
  end

  def edit
    @repository = JSONModel(:repository).find(params[:id])
  end

  def update
    handle_crud(:instance => :repository,
                :model => JSONModel(:repository),
                :obj => JSONModel(:repository).find(params[:id]),
                :on_invalid => ->(){ return render :action => :edit },
                :on_valid => ->(id){
                  MemoryLeak::Resources.refresh(:repository)

                  flash[:success] = I18n.t("repository._html.messages.updated")
                  redirect_to :controller => :repositories, :action => :show, :id => id
                })
  end

  def show
    @repository = JSONModel(:repository).find(params[:id])
    flash.now[:info] = I18n.t("repository._html.messages.selected") if @repository.id === session[:repo_id]
  end

  def select
    selected = @repositories.find {|r| r.id.to_s == params[:id]}
    session[:repo] = selected.repo_code
    session[:repo_id] = selected.id

    redirect_to :back
  end

end
