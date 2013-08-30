class LocationsController < ApplicationController

  set_access_control  "view_repository" => [:index, :show],
                      "update_location_record" => [:new, :edit, :create, :update, :batch, :batch_create]


  def index
    @search_data = Search.for_type(session[:repo_id], "location", params_for_backend_search.merge({"facet[]" => SearchResultData.LOCATION_FACETS}))
  end


  def get_location
    @location = JSONModel(:location).find(params[:id])
  end

  def show
    get_location
  end

  def new
    @location = JSONModel(:location).new._always_valid!
    render :partial => "locations/new" if inline?
  end

  def edit
    get_location
  end

  def create
    handle_crud(:instance => :location,
                :model => JSONModel(:location),
                :on_invalid => ->(){
                  return render :partial => "locations/new" if inline?
                  return render :action => :new
                },
                :on_valid => ->(id){
                  return render :json => @location.to_hash if inline?

                  flash[:success] = I18n.t("location._frontend.messages.created")
                  return redirect_to :controller => :locations, :action => :new if params.has_key?(:plus_one)

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

  def batch
    @location_batch = JSONModel(:location_batch).new
  end

  def batch_create
    begin
      batch = cleanup_params_for_schema(params[:location_batch], JSONModel(:location_batch).schema)

      @location_batch = JSONModel(:location_batch).from_hash(batch, false)

      uri = "#{JSONModel::HTTP.backend_url}/locations/batch"
      if params["dry_run"]
        uri += "?dry_run=true"
      end
      response = JSONModel::HTTP.post_json(URI(uri), batch.to_json)

      batch_response = ASUtils.json_parse(response.body)

      if batch_response.kind_of?(Hash) and batch_response.has_key?("error")
        if params["dry_run"]
          return render :partial => "shared/quick_messages", :locals => {:exceptions => batch_response, :jsonmodel => "location_batch"}
        else
          @exceptions = {:errors => batch_response["error"]}

          return render :action => :batch
        end
      end

      if params["dry_run"]
        render :partial => "locations/batch_preview", :locals => {:locations => batch_response}
      else
        flash[:success] = I18n.t("location_batch._frontend.messages.created", :number_created => batch_response.length)
        redirect_to :action => :index
      end
    rescue JSONModel::ValidationException => e
      @exceptions = @location_batch._exceptions

      return render :action => :batch
    end
  end

end
