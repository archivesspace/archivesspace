class AgentsController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:index, :show, :new, :edit, :create, :update, :list]
  before_filter :user_needs_to_be_a_viewer, :only => [:index, :show, :list]
  before_filter :user_needs_to_be_an_archivist, :only => [:new, :edit, :create, :update]

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

    render :partial => "agents/new" if inline?
  end

  def edit
    @agent = JSONModel(@agent_type).find(params[:id])
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
                  redirect_to :controller => :agents, :action => :show, :id => id, :type => @agent_type
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
                  redirect_to :controller => :agents, :action => :show, :id => id, :type => @agent_type
                })
  end

  def list
    if params[:q].blank?
      render :json => {:results => JSONModel::all('/agents', :agent_type)}
    else
      results = JSONModel::HTTP.get_json("/agents/by-name", {:q => params[:q].gsub(/\*/,"")})
      render :json => {
        :results => results.map{|r| {
          :id => r['uri'],
          :json => r.to_json
        }}
      }
    end
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
