class EventsController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:index, :show, :new, :edit, :create, :update]
  before_filter(:only => [:index, :show]) {|c| user_must_have("view_repository")}
  before_filter(:only => [:new, :edit, :create, :update]) {|c| user_must_have("update_archival_record")}

  def index
    @events = JSONModel(:event).all(:page => selected_page)
  end

  def show
    @event = JSONModel(:event).find(params[:id])
  end

  def new
    @event = JSONModel(:event).new._always_valid!
    @event.linked_agents = [{}]
    @event.linked_records = [{}]
    
    if params.has_key?(:event_type)
      @event.event_type = params[:event_type]
    end    

    if params.has_key?(:accession_uri)
      @event.linked_records = []
      
      accession = JSONModel(:accession).find_by_uri(params[:accession_uri])
      @event.linked_records << {'ref' => accession.uri, '_resolved' => accession.to_hash, 'role' => 'source'}
    end

  end

  def edit
    @event = JSONModel(:event).find(params[:id], "resolve[]" => ["linked_agents", "linked_records"])
  end

  def create
    handle_crud(:instance => :event,
                :model => JSONModel(:event),
                :on_invalid => ->(){
                  render :action => :new
                },
                :on_valid => ->(id){
                  flash[:success] = I18n.t("event._html.messages.created")
                  return redirect_to :controller => :events, :action => :new if params.has_key?(:plus_one)

                  redirect_to :controller => :events, :action => :index, :id => id
                })
  end

  def update
    handle_crud(:instance => :event,
                :model => JSONModel(:event),
                :obj => JSONModel(:event).find(params[:id]),
                :on_invalid => ->(){ render :action => :edit },
                :on_valid => ->(id){
                  flash[:success] = I18n.t("event._html.messages.updated")
                  redirect_to :controller => :events, :action => :index
                })
  end

end
