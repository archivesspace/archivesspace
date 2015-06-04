class EventsController < ApplicationController

  set_access_control  "view_repository" => [:index, :show],
                      "update_event_record" => [:new, :edit, :create, :update],
                      "delete_archival_record" => [:delete],
                      "manage_repository" => [:defaults, :update_defaults]



  def index
    @search_data = Search.for_type(session[:repo_id], "event", params_for_backend_search.merge({"facet[]" => SearchResultData.EVENT_FACETS}))
  end

  def show
    @event = JSONModel(:event).find(params[:id], find_opts)

    flash.now[:info] = I18n.t("event._frontend.messages.suppressed_info") if @event.suppressed
  end

  def new
    @event = JSONModel(:event).new._always_valid!
    @event.linked_agents = [{}]
    @event.linked_records = [{}]

    if user_prefs['default_values']
      defaults = DefaultValues.get 'event'

      @event.update(defaults.values) if defaults
    end


    if params.has_key?(:event_type)
      @event.event_type = params[:event_type]
    end

    if params.has_key?(:record_uri)
      @event.linked_records = []

      record = JSONModel(params[:record_type]).find_by_uri(params[:record_uri])
      @event.linked_records << {'ref' => record.uri, '_resolved' => record.to_hash, 'role' => 'source'}
      if request.referrer.end_with?("/edit")
        @redirect_action = 'edit'
      end
    end

  end

  def edit
    @event = JSONModel(:event).find(params[:id], find_opts)

    if @event.suppressed
      redirect_to(:controller => :events, :action => :show, :id => params[:id])
    end
  end

  def create
    handle_crud(:instance => :event,
                :model => JSONModel(:event),
                :on_invalid => ->(){
                  if params.has_key?(:redirect_action)
                    @redirect_action = params[:redirect_action]
                  end
                  render :action => :new
                },
                :on_valid => ->(id){
                  flash[:success] = I18n.t("event._frontend.messages.created")
                  return redirect_to :controller => :events, :action => :new if params.has_key?(:plus_one)

                  if params.has_key?(:redirect_record)
                    ref = JSONModel.parse_reference(params[:redirect_record])
                    redirect_action = :show
                    if !params[:redirect_action].blank?
                      redirect_action = params[:redirect_action].intern
                    end
                    if ref[:type].include?('agent_')
                      redirect_to :controller => "agents", :action => redirect_action, :id => ref[:id], :agent_type => ref[:type]
                    else
                      redirect_to :controller => ref[:type].pluralize, :action => redirect_action, :id => ref[:id]
                    end
                  else
                    redirect_to :controller => :events, :action => :edit, :id => id
                  end
                })
  end

  def update
    handle_crud(:instance => :event,
                :model => JSONModel(:event),
                :obj => JSONModel(:event).find(params[:id]),
                :on_invalid => ->(){ render :action => :edit },
                :on_valid => ->(id){
                  flash[:success] = I18n.t("event._frontend.messages.updated")
                  redirect_to :controller => :events, :action => :edit, :id => id
                })
  end


  def delete
    event = JSONModel(:event).find(params[:id])
    event.delete

    flash[:success] = I18n.t("event._frontend.messages.deleted", JSONModelI18nWrapper.new(:event => event))
    redirect_to(:controller => :events, :action => :index, :deleted_uri => event.uri)
  end


  def defaults
    defaults = DefaultValues.get 'event'

    values = defaults ? defaults.form_values : {}

    @event = JSONModel(:event).new(values)._always_valid!

    render "defaults"
  end

  def update_defaults

    begin
      DefaultValues.from_hash({
                                "record_type" => "event",
                                "lock_version" => params[:event].delete('lock_version'),
                                "defaults" => cleanup_params_for_schema(
                                                                        params[:event],
                                                                        JSONModel(:event).schema)
                              }).save

      flash[:success] = I18n.t("default_values.messages.defaults_updated")
      redirect_to :controller => :events, :action => :defaults
    rescue Exception => e
      flash[:error] = e.message
      redirect_to :controller => :events, :action => :defaults
    end
  end

end
