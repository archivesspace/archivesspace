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
        csv_response( uri, Search.build_filters(search_params), "#{t('event._plural').downcase}." )
      }
    end
  end

  def current_record
    @event
  end

  def show
    @event = JSONModel(:event).find(params[:id], find_opts)

    flash.now[:info] = t("event._frontend.messages.suppressed_info") if @event.suppressed
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
                :before_hooks => [method(:ensure_required_linked_agents), method(:ensure_required_linked_records)],
                :on_invalid => ->() {
                  if params.has_key?(:redirect_action)
                    @redirect_action = params[:redirect_action]
                  end

                  # Ensure Agent Links and Record Links subforms are visible after validation errors
                  # by reintroducing a single blank subrecord when none are present.
                  @event.linked_agents = [{}] if @event.linked_agents.blank?
                  @event.linked_records = [{}] if @event.linked_records.blank?

                  # Transform list-level error into field-level errors for Agent Links and Record Links.
                  if defined?(@exceptions) && @exceptions && @exceptions[:errors]
                    errors = @exceptions[:errors]

                    if errors.key?('linked_agents') || errors.key?(:linked_agents)
                      errors.delete('linked_agents')
                      errors.delete(:linked_agents)

                      %w[ref role].each do |field|
                        key = "linked_agents/0/#{field}"
                        errors[key] ||= []
                        errors[key] << I18n.t('validation_errors.missing_required_property')
                      end
                    end

                    if errors.key?('linked_records') || errors.key?(:linked_records)
                      errors.delete('linked_records')
                      errors.delete(:linked_records)

                      %w[ref role].each do |field|
                        key = "linked_records/0/#{field}"
                        errors[key] ||= []
                        errors[key] << I18n.t('validation_errors.missing_required_property')
                      end
                    end

                    # When date_type is 'single', we only care about the 'begin' field,
                    # so suppress the unrelated 'end' field error
                    if @event && @event['date'] && @event['date']['date_type'] == 'single'
                      errors.keys.each do |key|
                        if key.to_s =~ /^date(\/\d+)?\/end$/
                          errors.delete(key)
                        end
                      end
                    end

                    @exceptions[:errors] = errors
                  end

                  render :action => :new
                },
                :on_valid => ->(id) {
                  flash[:success] = t("event._frontend.messages.created")
                  if params.has_key?(:plus_one)
                    # This is confusing because redirect_record is used as the resource/etc to which this event is
                    # linked to, and should indeed redirect to that record in the case of the Save button being pressed.
                    # (Or to the edit page of the new event if Create->Event from the main menu was used.)
                    # However, if the +1 button is used, we are redirecting to a new event, but still want to
                    # keep the link to that resource, hence the hijacking of redirect_record for that purpose, but
                    # not actually redirecting to it.
                    if params.has_key?(:redirect_record)
                      return redirect_to(
                        :controller => :events,
                        :action => :new,
                        :record_uri => params[:redirect_record],
                        :record_type => JSONModel.parse_reference(params[:redirect_record])[:type])
                    else
                      # If +1 was used from a New Event created via Create->Event in the menu, we will not automatically
                      # link the next event to any record, even if there were linked events added to it. This is because
                      # the intent to link events to a single previously existing resource was not expressed by coming
                      # here from an Add Event button on a resource, and the user could have linked any number of
                      # resources (or none) on this fresh standalone event.
                      return redirect_to(:controller => :events, :action => :new)
                    end
                  end

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
                  flash[:success] = t("event._frontend.messages.updated")
                  redirect_to :controller => :events, :action => :edit, :id => id
                })
  end

  def delete
    event = JSONModel(:event).find(params[:id])
    event.delete
    flash[:success] = t("event._frontend.messages.deleted")
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

      flash[:success] = t("default_values.messages.defaults_updated")
      redirect_to :controller => :events, :action => :defaults
    rescue Exception => e
      flash[:error] = e.message
      redirect_to :controller => :events, :action => :defaults
    end
  end

  private

  # Ensure the required Agent and Record Links subrecords exist before validation so that
  # field-level errors (eg, Role and Agent) are produced instead of only a list-level error.
  def ensure_required_linked_agents(instance)
    if instance['linked_agents'].nil? || (instance['linked_agents'].respond_to?(:empty?) && instance['linked_agents'].empty?)
      instance['linked_agents'] = [{}]
    end
  end

  def ensure_required_linked_records(instance)
    if instance['linked_records'].nil? || (instance['linked_records'].respond_to?(:empty?) && instance['linked_records'].empty?)
      instance['linked_records'] = [{}]
    end
  end
end
