class AgentsController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:index, :show, :new, :edit, :create, :update, :delete,
                                                     :merge]
  before_filter(:only => [:index, :show]) {|c| user_must_have("view_repository")}
  before_filter(:only => [:new, :edit, :create, :update, :merge]) {|c| user_must_have("update_agent_record")}
  before_filter(:only => [:delete]) {|c| user_must_have("delete_archival_record")}

  before_filter :assign_types

  FIND_OPTS = {
    "resolve[]" => ["related_agents"]
  }

  def index
    @search_data = Search.for_type(session[:repo_id], "agent", {"sort" => "title_sort asc"}.merge(search_params.merge({"facet[]" => SearchResultData.AGENT_FACETS})))
  end

  def show
    @agent = JSONModel(@agent_type).find(params[:id], FIND_OPTS)
  end

  def new
    @agent = JSONModel(@agent_type).new({:agent_type => @agent_type})._always_valid!
    @agent.names = [@name_type.new._always_valid!]

    render :partial => "agents/new" if inline?
  end

  def edit
    @agent = JSONModel(@agent_type).find(params[:id], FIND_OPTS)
  end

  def create
    handle_crud(:instance => :agent,
                :model => JSONModel(@agent_type),
                :find_opts => FIND_OPTS,
                :on_invalid => ->(){
                  return render :partial => "agents/new" if inline?
                  return render :action => :new
                },
                :on_valid => ->(id){
                  return render :json => @agent.to_hash if inline?
                  return redirect_to({:controller => :agents, :action => :new, :agent_type => @agent_type}, :flash => {:success => I18n.t("agent._frontend.messages.created")}) if params.has_key?(:plus_one)
                  redirect_to({:controller => :agents, :action => :show, :id => id, :agent_type => @agent_type}, :flash => {:success => I18n.t("agent._frontend.messages.created")})
                })
  end

  def update
    handle_crud(:instance => :agent,
                :model => JSONModel(@agent_type),
                :obj => JSONModel(@agent_type).find(params[:id], FIND_OPTS),
                :on_invalid => ->(){

                  if @agent.names.empty?
                    @agent.names = [@name_type.new._always_valid!]
                  end

                  return render :action => :edit
                },
                :on_valid => ->(id){
                  flash[:success] = I18n.t("agent._frontend.messages.updated")
                  redirect_to :controller => :agents, :action => :show, :id => id, :agent_type => @agent_type
                })
  end


  def delete
    agent = JSONModel(@agent_type).find(params[:id])

    begin
      agent.delete
    rescue ConflictException => e
      flash[:error] = e.conflicts
      redirect_to(:controller => :agents, :action => :show, :id => params[:id])
      return
    end

    flash[:success] = I18n.t("agent._frontend.messages.deleted", JSONModelI18nWrapper.new(:agent => agent))
    redirect_to(:controller => :agents, :action => :index, :deleted_uri => agent.uri)
  end


  def merge
    handle_merge(JSONModel(@agent_type).uri_for(params[:id]),
                 params[:ref],
                 'agent',
                 {:agent_type => @agent_type})
  end


  private

    def name_type_for_agent_type(agent_type)
      JSONModel(agent_type).type_of("names/items")
    end

    def assign_types
      return if not params.has_key? 'agent_type'

      @agent_type = :"#{params[:agent_type]}"
      @name_type = name_type_for_agent_type(@agent_type)
    end
end
