class LocationsController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:index, :show, :list, :new, :edit, :create, :update]
  before_filter :user_needs_to_be_a_viewer, :only => [:index, :show, :list]
  before_filter :user_needs_to_be_an_archivist, :only => [:new, :edit, :create, :update]

  def index
    @locations = Location.all(:page => selected_page)
  end

  def show
    @location = Location.find(params[:id])
  end

  def new
    @location = JSONModel(:location).new._always_valid!
    render :partial => "locations/new" if inline?
  end

  def edit
    @location = Location.find(params[:id])
  end

  def create
    handle_crud(:instance => :location,
                :model => Location,
                :on_invalid => ->(){
                  return render :partial => "locations/new" if inline?
                  return render :action => :new
                },
                :on_valid => ->(id){
                  if inline?
                    render :json => @location.to_hash if inline?
                  else
                    redirect_to :controller => :locations, :action => :show, :id => id
                  end
                })
  end

  def update
    handle_crud(:instance => :location,
                :model => Location,
                :obj => Location.find(params[:id]),
                :on_invalid => ->(){ return render :action => :edit },
                :on_valid => ->(id){
                  flash[:success] = "Location Saved"
                  redirect_to :controller => :locations, :action => :show, :id => id
                })
  end

  def list
    locations = Location.all(:page => selected_page)

    if params[:q]
      locations = locations.select {|l| l.display_string.downcase.include?(params[:q].downcase)}
    end

    respond_to do |format|
      format.json {
        render :json => locations
      }
    end
  end

end
