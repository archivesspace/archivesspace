class EventsController < ApplicationController

  set_access_control  "view_repository" => [:index, :show],
                      "update_event_record" => [:new, :edit, :create, :update],
                      "delete_event_record" => [:delete],
                      "manage_repository" => [:defaults, :update_defaults]


  include ExportHelper

  def index
    respond_to do |format|
      format.html {
        @search_data = Search.for_type(session[:repo_id], "event", params_for_backend_search.merge({"facet[]" => SearchResultData.EVENT_FACETS}))
      }
      format.csv {
        search_params = params_for_backend_search.merge({"facet[]" => SearchResultData.EVENT_FACETS})
        search_params["type[]"] = "event"

        # ANW-1635: when outputting to CSV, use linked_record_titles instead of linked_records since that's where the linked record data is available in the solr schema
        if search_params["fields[]"].include?("linked_records")
          search_params["fields[]"].delete("linked_records")
          search_params["fields[]"].push("linked_record_titles")
        end

        uri = "/repositories/#{session[:repo_id]}/search"
        csv_response( uri, Search.build_filters(search_params), "#{I18n.t('event._plural').downcase}." )
      }
    end
  end

  def current_record
    @event
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
      @last_linked_record_uri = params[:record_uri]
      @last_linked_record_type = params[:record_type]
      @last_linked_record_path = params[:record_uri].match('\/\w+\/\d+$')[0]

      record = JSONModel(params[:record_type]).find_by_uri(params[:record_uri])
      @event.linked_records = []
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
                :on_invalid => ->() {
                  if params.has_key?(:redirect_action)
                    @redirect_action = params[:redirect_action]
                  end
                  render :action => :new
                },
                :on_valid => ->(id) {
                  flash[:success] = I18n.t("event._frontend.messages.created")
                  return redirect_to(
                    :controller => :events,
                    :action => :new,
                    :record_uri => params[:redirect_record],
                    :record_type => JSONModel.parse_reference(params[:redirect_record])[:type]) if params.has_key?(:plus_one)

                  # we parse the reference as a simple sanity check here...
                  if params.has_key?(:redirect_record) && JSONModel.parse_reference(params[:redirect_record])
                    if params[:redirect_action].blank?
                      redirect_action = :show
                    else
                      redirect_action = params[:redirect_action].intern
                    end

                    redirect_to(:controller => :resolver,
                                :action => (redirect_action == :edit) ? :resolve_edit : :resolve_readonly,
                                :uri => params[:redirect_record])
                  else
                    redirect_to :controller => :events, :action => :edit, :id => id
                  end
                })
  end

  def update
    handle_crud(:instance => :event,
                :model => JSONModel(:event),
                :obj => JSONModel(:event).find(params[:id]),
                :on_invalid => ->() { render :action => :edit },
                :on_valid => ->(id) {
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
