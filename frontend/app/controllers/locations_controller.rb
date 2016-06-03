class LocationsController < ApplicationController

  set_access_control  "view_repository" => [:index, :show, :search],
                      "update_location_record" => [:new, :edit, :create, :update, :batch, :batch_create, :delete],
                      "manage_repository" => [:defaults, :update_defaults]


  LOCATION_STICKY_PARAMS = ["building", "floor", "room", "area" ]
  include ExportHelper

  def index
    respond_to do |format| 
      format.html {   
        @search_data = Search.for_type(session[:repo_id], "location", params_for_backend_search.merge({"facet[]" => SearchResultData.LOCATION_FACETS}))
      }
      format.csv { 
        search_params = params_for_backend_search.merge({"facet[]" => SearchResultData.LOCATION_FACETS})
        search_params["type[]"] = "location"
        uri = "/repositories/#{session[:repo_id]}/search"
        csv_response( uri, search_params )
      }  
    end 
  end


  def get_location
    @location = JSONModel(:location).find(params[:id], find_opts)
  end

  def show
    get_location
  end

  def new
    location_params = params.inject({}) { |c, (k,v)| c[k] = v if LOCATION_STICKY_PARAMS.include?(k); c }
    @location = JSONModel(:location).new(location_params)._always_valid!

    if user_prefs['default_values']
      defaults = DefaultValues.get 'location'

      @location.update(defaults.values) if defaults
    end


    render_aspace_partial :partial => "locations/new" if inline?
  end

  def edit
    get_location
  end

  def create
    handle_crud(:instance => :location,
                :model => JSONModel(:location),
                :on_invalid => ->(){
                  return render_aspace_partial :partial => "locations/new" if inline?
                  return render :action => :new
                },
                :on_valid => ->(id){
                  return render :json => @location.to_hash if inline?

                  flash[:success] = I18n.t("location._frontend.messages.created")
                  if params.has_key?(:plus_one)
                     sticky_params = { :controller => :locations, :action => :new}
                     @location.to_hash.each_pair do |k,v|
                        sticky_params[k] = v if LOCATION_STICKY_PARAMS.include?(k)
                     end

                     return redirect_to sticky_params
                  end
                  redirect_to :controller => :locations, :action => :edit, :id => id
                })
  end

  def update
    handle_crud(:instance => :location,
                :model => JSONModel(:location),
                :obj => JSONModel(:location).find(params[:id]),
                :on_invalid => ->(){ return render :action => :edit },
                :on_valid => ->(id){
                  flash[:success] = I18n.t("location._frontend.messages.updated")
                  redirect_to :controller => :locations, :action => :edit, :id => id
                })
  end

  def defaults
    defaults = DefaultValues.get 'location'

    values = defaults ? defaults.form_values : {}

    @location = JSONModel(:location).new(values)._always_valid!

    render "defaults"
  end

  def update_defaults

    begin
      DefaultValues.from_hash({
                                "record_type" => "location",
                                "lock_version" => params[:location].delete('lock_version'),
                                "defaults" => cleanup_params_for_schema(
                                                                        params[:location],
                                                                        JSONModel(:location).schema)
                              }).save

      flash[:success] = I18n.t("default_values.messages.defaults_updated")
      redirect_to :controller => :locations, :action => :defaults
    rescue Exception => e
      flash[:error] = e.message
      redirect_to :controller => :locations, :action => :defaults
    end
  end


  def batch
    @is_batch_update = false
    @action = "create" # we use this for some label in the view..

    if request.post? # if it's a post, we're starting an update
      @is_batch_update = true
      @action = "update" # we use this for some label in the view..
      @location_batch = JSONModel(:location_batch_update).new(params)._always_valid!
    else # we're just creatinga new batch from scratch
      location_params = params.inject({}) { |c, (k,v)| c[k] = v if LOCATION_STICKY_PARAMS.include?(k); c }
      @location_batch = JSONModel(:location_batch).new(location_params)
    end
  end



  def batch_create

    begin
      if params[:location_batch][:record_uris] && params[:location_batch][:record_uris].length > 0
        batch = cleanup_params_for_schema(params[:location_batch], JSONModel(:location_batch_update).schema)
        @location_batch = JSONModel(:location_batch_update).from_hash(batch, false)._always_valid!

        uri = "#{JSONModel::HTTP.backend_url}/locations/batch_update"
        response = JSONModel::HTTP.post_json(URI(uri), batch.to_json)

        batch_response = ASUtils.json_parse(response.body)
      else

        batch = cleanup_params_for_schema(params[:location_batch], JSONModel(:location_batch).schema)

        @location_batch = JSONModel(:location_batch).from_hash(batch, false)

        uri = "#{JSONModel::HTTP.backend_url}/locations/batch"
        if params["dry_run"]
          uri += "?dry_run=true"
        end
        response = JSONModel::HTTP.post_json(URI(uri), batch.to_json)

        batch_response = ASUtils.json_parse(response.body)
      end

      if batch_response.kind_of?(Hash) and batch_response.has_key?("error")
        if params["dry_run"]
          return render_aspace_partial :partial => "shared/quick_messages", :locals => {:exceptions => batch_response, :jsonmodel => "location_batch"}
        else
          @exceptions = {:errors => batch_response["error"]}

          return render :action => :batch
        end
      end

      if params["dry_run"]
        render_aspace_partial :partial => "locations/batch_preview", :locals => {:locations => batch_response}
      else

        # we want 'created' or 'updated' messages displayed
        if @location_batch.jsonmodel_type == "location_batch_update"
          flash[:success] = I18n.t("location_batch._frontend.messages.updated", :number_created => batch_response.length)
        else
          flash[:success] = I18n.t("location_batch._frontend.messages.created", :number_created => batch_response.length)
        end

        if params.has_key?(:plus_one)
           sticky_params = { :controller => :locations, :action => :batch}
           @location_batch.to_hash.each_pair do |k,v|
              sticky_params[k] = v if LOCATION_STICKY_PARAMS.include?(k)
           end

           return redirect_to sticky_params
        end
        redirect_to :action => :index
      end
    rescue JSONModel::ValidationException => e
      @exceptions = @location_batch._exceptions

      return render :action => :batch
    end
  end


  def delete
    location = JSONModel(:location).find(params[:id])
    begin
      location.delete
    rescue ConflictException => e
      flash[:error] = location.translate_exception_message(e.conflicts)
      return redirect_to(:controller => :locations, :action => :show, :id => location.id)
    end

    flash[:success] = I18n.t("location._frontend.messages.deleted", JSONModelI18nWrapper.new(:location => location))
    redirect_to(:controller => :locations, :action => :index, :deleted_uri => location.uri)
  end


  def search
    respond_to do |format|
      format.js {
        @search_data = Search.all(session[:repo_id], params_for_backend_search.merge({"facet[]" => SearchResultData.LOCATION_FACETS}))
        @display_identifier = false
        @extra_columns = []
        @search_data.sort_fields << "location_profile_display_string_u_ssort"
        @extra_columns << SearchHelper::ExtraColumn.new(I18n.t("location_profile._singular"),
                                         proc {|record| record["location_profile_display_string_u_ssort"]},
                                         { :sortable => true, :sort_by => "location_profile_display_string_u_ssort" },
                                         @search_data)

        render_aspace_partial :partial => "search/results"
      }
    end
  end
end
