class AgentsController < ApplicationController

  def index
    #TODO
    @agents = []
  end

  def show
    @agent = JSONModel(:"#{params[:type]}").find(params[:id])
  end

  def new
    @agent = JSONModel(:"#{params[:type]}").new({:type => "agent_person"})._always_valid!
    @agent.names = [JSONModel(:name_person).new._always_valid!]
  end

  def edit
    @agent = JSONModel(:"#{params[:type]}").find(params[:id])
  end

  def create
    handle_crud(:instance => :"#{params[:type]}",
                :model => JSONModel(:"#{params[:type]}"),
                :on_invalid => ->(){
                  return render :action => :new
                },
                :on_valid => ->(id){
                  redirect_to :controller => :agents, :action => :show, :id => id, :type => params[:type]
                })
  end

end
