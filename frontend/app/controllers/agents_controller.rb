class AgentsController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:index, :show, :new, :edit, :create, :update]
  before_filter(:only => [:index, :show]) {|c| user_must_have("view_repository")}
  before_filter(:only => [:new, :edit, :create, :update]) {|c| user_must_have("update_agent_record")}

  before_filter :assign_types

  def index
    facets = ["primary_type", "source", "rules"]

    @search_data = Search.for_type(session[:repo_id], "agent", search_params.merge({"facet[]" => facets}))
  end

  def show
    @agent = JSONModel(@agent_type).find(params[:id], "resolve[]" => "related_agents")
  end

  def new
    @agent = JSONModel(@agent_type).new({:agent_type => @agent_type})._always_valid!
    @agent.names = [@name_type.new._always_valid!]

    render :partial => "agents/new" if inline?
  end

  def edit
    @agent = JSONModel(@agent_type).find(params[:id], "resolve[]" => "related_agents")
  end

  def create
    handle_crud(:instance => :agent,
                :model => JSONModel(@agent_type),
                :on_invalid => ->(){
                  return render :partial => "agents/new" if inline?
                  return render :action => :new
                },
                :on_valid => ->(id){
                  return render :json => @agent.to_hash if inline?
                  return redirect_to({:controller => :agents, :action => :new, :type => @agent_type}, :flash => {:success => I18n.t("agent._html.messages.created")}) if params.has_key?(:plus_one)
                  redirect_to({:controller => :agents, :action => :show, :id => id, :type => @agent_type}, :flash => {:success => I18n.t("agent._html.messages.created")})
                })
  end

  def update
    handle_crud(:instance => :agent,
                :model => JSONModel(@agent_type),
                :obj => JSONModel(@agent_type).find(params[:id]),
                :on_invalid => ->(){

                  if @agent.names.empty?
                    @agent.names = [@name_type.new._always_valid!]
                  end

                  return render :action => :edit
                },
                :on_valid => ->(id){
                  flash[:success] = I18n.t("agent._html.messages.updated")
                  redirect_to :controller => :agents, :action => :show, :id => id, :type => @agent_type
                })
  end


  private

    def name_type_for_agent_type(agent_type)
      JSONModel(agent_type).type_of("names/items")
    end

    def assign_types
      return if not params.has_key? 'type'

      @agent_type = :"#{params[:type]}"
      @name_type = name_type_for_agent_type(@agent_type)
    end
end
