class EventsController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:index, :show, :list, :new, :edit, :create, :update, :listrecords]
  before_filter :user_needs_to_be_a_viewer, :only => [:index, :show, :list]
  before_filter :user_needs_to_be_an_archivist, :only => [:new, :edit, :create, :update]

  def index
    @events = JSONModel(:event).all
  end

  def show
    @event = JSONModel(:event).find(params[:id])
  end

  def new
    @event = JSONModel(:event).new._always_valid!
    @event.linked_agents = [{}]
    @event.linked_records = [{}]
  end

  def edit
    @event = JSONModel(:event).find(params[:id])
  end

  def create
    handle_crud(:instance => :event,
                :model => JSONModel(:event),
                :on_invalid => ->(){
                  render :action => :new
                },
                :on_valid => ->(id){
                  redirect_to :controller => :events, :action => :show, :id => id
                })
  end

  def update
    handle_crud(:instance => :event,
                :model => JSONModel(:event),
                :obj => JSONModel(:event).find(params[:id]),
                :on_invalid => ->(){ render :action => :edit },
                :on_valid => ->(id){
                  flash[:success] = "Event Saved"
                  render :action => :show
                })
  end


  def listrecords
    render :json => [] if params[:q].blank?

    render :json => JSONModel::HTTP.get_json(JSONModel(:event).uri_for('linkable-records/list'),
                                             :q => params[:q])
  end

end
