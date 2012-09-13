class AgentsController < ApplicationController

  def index
    @agents = JSONModel::all('/agents', :agent_type)
  end

  def show
    @agent = JSONModel(:"#{params[:type]}").find(params[:id])
  end

  def new
    @name_type = :name_person
    @agent = JSONModel(:"#{params[:type]}").new({:agent_type => params[:type]})._always_valid!
    @agent.names = [JSONModel(@name_type).new._always_valid!]
  end

  def edit
    @name_type = :name_person
    @agent = JSONModel(:"#{params[:type]}").find(params[:id])
  end

  def create
    @name_type = :name_person
    handle_crud(:instance => :agent,
                :model => JSONModel(:"#{params[:type]}"),
                :on_invalid => ->(){
                  return render :action => :new
                },
                :on_valid => ->(id){
                  redirect_to :controller => :agents, :action => :show, :id => id, :type => params[:type]
                })
  end

  def update
    @name_type = :name_person
    handle_crud(:instance => :agent,
                :model => JSONModel(:"#{params[:type]}"),
                :on_invalid => ->(){
                  return render :action => :edit
                },
                :on_valid => ->(id){
                  redirect_to :controller => :agents, :action => :show, :id => id, :type => params[:type]
                })
  end
end
