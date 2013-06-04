class LocationsController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:index, :show, :new, :edit, :create, :update, :batch, :batch_create]
  before_filter(:only => [:index, :show]) {|c| user_must_have("view_repository")}
  before_filter(:only => [:new, :edit, :create, :update, :batch, :batch_create]) {|c| user_must_have("update_location_record")}

  def index
    @search_data = Search.for_type(session[:repo_id], "location", search_params.merge({"facet[]" => SearchResultData.LOCATION_FACETS}))
  end

  def show
    @location = JSONModel(:location).find(params[:id])
  end

  def new
    @location = JSONModel(:location).new._always_valid!
    render :partial => "locations/new" if inline?
  end

  def edit
    @location = JSONModel(:location).find(params[:id])
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

                  redirect_to :controller => :locations, :action => :show, :id => id
                })
  end

  def update
    handle_crud(:instance => :location,
                :model => JSONModel(:location),
                :obj => JSONModel(:location).find(params[:id]),
                :on_invalid => ->(){ return render :action => :edit },
                :on_valid => ->(id){
                  flash[:success] = I18n.t("location._frontend.messages.updated")
                  redirect_to :controller => :locations, :action => :show, :id => id
                })
  end

  def batch
    @location_batch = JSONModel(:location_batch).new
  end

  def batch_create
    begin
      batch = cleanup_params_for_schema(params[:location_batch], JSONModel(:location_batch).schema)

      @location_batch = JSONModel(:location_batch).from_hash(batch, false)

      uri = "#{JSONModel::HTTP.backend_url}/repositories/#{session[:repo_id]}/locations/batch"
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
