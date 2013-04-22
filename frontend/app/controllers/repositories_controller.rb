class RepositoriesController < ApplicationController

  skip_before_filter :unauthorised_access, :only => [:new, :create, :select, :index, :show, :edit, :update]
  before_filter(:only => [:select, :index, :show]) {|c| user_must_have("view_repository")}
  before_filter(:only => [:new, :create, :edit, :update]) {|c| user_must_have("manage_repository")}

  before_filter :refresh_repo_list, :only => [:show, :new]

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
            
                  flash[:success] = I18n.t("repository._html.messages.created", JSONModelI18nWrapper.new(:repository => @repository))
                  return redirect_to :controller => :repositories, :action => :new, :last_repo_id => id if params.has_key?(:plus_one)
            
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

                  flash[:success] = I18n.t("repository._html.messages.updated", JSONModelI18nWrapper.new(:repository => @repository))
                  redirect_to :controller => :repositories, :action => :show, :id => id
                })
  end

  def show
    @repository = JSONModel(:repository).find(params[:id])
    flash.now[:info] = I18n.t("repository._html.messages.selected") if @repository.id === session[:repo_id]
  end

  def select
    selected = @repositories.find {|r| r.id.to_s == params[:id]}
    session[:repo] = selected.uri
    session[:repo_id] = selected.id

    flash[:success] = I18n.t("repository._html.messages.changed", JSONModelI18nWrapper.new(:repository => selected))

    redirect_to :root
  end

  private

    def refresh_repo_list
      repo_uri = JSONModel(:repository).uri_for(params[:last_repo_id] || params[:id])
      if @repositories.none?{|repo| repo["uri"] === repo_uri}
        MemoryLeak::Resources.refresh(:repository)
        load_repository_list
      end
    end

end
