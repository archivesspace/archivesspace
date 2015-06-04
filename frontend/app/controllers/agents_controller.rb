class AgentsController < ApplicationController

  set_access_control  "view_repository" => [:index, :show],
                      "update_agent_record" => [:new, :edit, :create, :update, :merge],
                      "delete_agent_record" => [:delete],
                      "manage_repository" => [:defaults, :update_defaults]


  before_filter :assign_types

  def index
    @search_data = Search.for_type(session[:repo_id], "agent", {"sort" => "title_sort asc"}.merge(params_for_backend_search.merge({"facet[]" => SearchResultData.AGENT_FACETS})))
  end

  def show
    @agent = JSONModel(@agent_type).find(params[:id], find_opts)
  end

  def new
    @agent = JSONModel(@agent_type).new({:agent_type => @agent_type})._always_valid!
    if user_prefs['default_values']
      defaults = DefaultValues.get @agent_type.to_s

      @agent.update(defaults.values) if defaults
    end

    if @agent.names.empty?
      @agent.names = [@name_type.new({:authorized => true, :is_display_name => true})._always_valid!]
    end

    render_aspace_partial :partial => "agents/new" if inline?
  end

  def edit
    @agent = JSONModel(@agent_type).find(params[:id], find_opts)
  end

  def create
    handle_crud(:instance => :agent,
                :model => JSONModel(@agent_type),
                :find_opts => find_opts,
                :on_invalid => ->(){
                  return render_aspace_partial :partial => "agents/new" if inline?
                  return render :action => :new
                },
                :on_valid => ->(id){
                  return render :json => @agent.to_hash if inline?
                  return redirect_to({:controller => :agents, :action => :new, :agent_type => @agent_type}, :flash => {:success => I18n.t("agent._frontend.messages.created")}) if params.has_key?(:plus_one)
                  redirect_to({:controller => :agents, :action => :edit, :id => id, :agent_type => @agent_type}, :flash => {:success => I18n.t("agent._frontend.messages.created")})
                })
  end

  def update
    handle_crud(:instance => :agent,
                :model => JSONModel(@agent_type),
                :obj => JSONModel(@agent_type).find(params[:id], find_opts),
                :on_invalid => ->(){

                  if @agent.names.empty?
                    @agent.names = [@name_type.new._always_valid!]
                  end

                  return render :action => :edit
                },
                :on_valid => ->(id){
                  flash[:success] = I18n.t("agent._frontend.messages.updated")
                  redirect_to :controller => :agents, :action => :edit, :id => id, :agent_type => @agent_type
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

  def defaults
    defaults = DefaultValues.get params['agent_type']

    @agent = JSONModel(@agent_type).new({:agent_type => @agent_type})._always_valid!

    @agent.update(defaults.form_values) if defaults

    render 'defaults'
  end

  def update_defaults

    begin

      DefaultValues.from_hash({
                                "record_type" => @agent_type.to_s,
                                "lock_version" => params['agent'].delete('lock_version'),
                                "defaults" => cleanup_params_for_schema(
                                                                        params['agent'],
                                                                        JSONModel(@agent_type).schema)
                              }).save

      flash[:success] = I18n.t("default_values.messages.defaults_updated")
      redirect_to :controller => :agents, :action => :defaults
    rescue Exception => e
      flash[:error] = e.message
      redirect_to :controller => :agents, :action => :defaults
    end
  end



  def merge
    handle_merge( params[:refs],
                  JSONModel(@agent_type).uri_for(params[:id]),
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
