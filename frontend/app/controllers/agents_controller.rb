class AgentsController < ApplicationController

  def index
    #TODO
    @agents = []
  end

  def show
    @agent = JSONModel(:"#{params[:type]}").find(params[:id])
  end

  def new
    @agent = JSONModel(:"#{params[:type]}").new({:agent_type => params[:type]})._always_valid!
    @agent.names = [JSONModel(:name_person).new._always_valid!]
  end

  def edit
    @agent = JSONModel(:"#{params[:type]}").find(params[:id])
  end

  def create
    handle_crud(:instance => :agent,
                :model => JSONModel(:"#{params[:type]}"),
                :on_invalid => ->(){
                  return render :action => :new
                },
                :on_valid => ->(id){
                  redirect_to :controller => :agents, :action => :show, :id => id, :type => params[:type]
                })
  end

  def name_form
    render :partial => "agents/name_forms/secondary_name_form", :locals=>{:agent_type => params[:type]}
  end

  def contact_form
    render :partial => "agents/contact_details"
  end

end
