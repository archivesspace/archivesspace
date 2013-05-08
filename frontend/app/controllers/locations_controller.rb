class LocationsController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:index, :show, :new, :edit, :create, :update]
  before_filter(:only => [:index, :show]) {|c| user_must_have("view_repository")}
  before_filter(:only => [:new, :edit, :create, :update]) {|c| user_must_have("update_location_record")}

  def index
    @search_data = JSONModel(:location).all(:page => selected_page)
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

end
