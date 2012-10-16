class LocationsController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:index, :show, :list, :new, :edit, :create, :update]
  before_filter :user_needs_to_be_a_viewer, :only => [:index, :show, :list]
  before_filter :user_needs_to_be_an_archivist, :only => [:new, :edit, :create, :update]

  def index
    @locations = JSONModel(:location).all
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
                  if inline?
                    render :json => @location.to_hash if inline?
                  else
                    redirect_to :controller => :locations, :action => :show, :id => id
                  end
                })
  end

  def update
    handle_crud(:instance => :location,
                :model => JSONModel(:location),
                :obj => JSONModel(:location).find(params[:id]),
                :on_invalid => ->(){ return render :action => :edit },
                :on_valid => ->(id){
                  flash[:success] = "Location Saved"
                  redirect_to :controller => :locations, :action => :show, :id => id
                })
  end

end
