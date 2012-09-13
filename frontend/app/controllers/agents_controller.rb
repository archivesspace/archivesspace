class AgentsController < ApplicationController
  before_filter :assign_types

  def index
    @agents = JSONModel::all('/agents', :agent_type)
  end

  def show
    @agent = JSONModel(@agent_type).find(params[:id])
  end

  def new
    @agent = JSONModel(@agent_type).new({:agent_type => @agent_type})._always_valid!
    @agent.names = [@name_type.new._always_valid!]
  end

  def edit
    @agent = JSONModel(@agent_type).find(params[:id])
  end

  def create
    handle_crud(:instance => :agent,
                :model => JSONModel(@agent_type),
                :on_invalid => ->(){
                  return render :action => :new
                },
                :on_valid => ->(id){
                  redirect_to :controller => :agents, :action => :show, :id => id, :type => @agent_type
                })
  end

  def update
    handle_crud(:instance => :agent,
                :model => JSONModel(@agent_type),
                :on_invalid => ->(){
                  return render :action => :edit
                },
                :on_valid => ->(id){
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
