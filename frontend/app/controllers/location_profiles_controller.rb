class LocationProfilesController < ApplicationController

  include ExportHelper

  set_access_control  "view_repository" => [:show, :typeahead],
                      "manage_location_profile_record" => [:new, :index, :edit, :create, :update, :delete]

  FACETS = ["location_profile_width_u_sstr", "location_profile_height_u_sstr", "location_profile_depth_u_sstr", "location_profile_dimension_units_u_sstr"]


  def self.FACETS
    FACETS
  end

  def new
    @location_profile = JSONModel(:location_profile).new._always_valid!

    render_aspace_partial :partial => "location_profiles/new" if inline?
  end


  def index
    respond_to do |format|
      format.html {
        @search_data = Search.global(params_for_backend_search.merge({"facet[]" => FACETS}), "location_profile")
      }

      format.csv {
        search_params = params_for_backend_search.merge({"facet[]" => FACETS})
        search_params["type[]"] = "location_profile"
        uri = "/repositories/#{session[:repo_id]}/search"
        csv_response( uri, Search.build_filters(search_params), "#{I18n.t('location_profile._plural').downcase}." )
      }
    end
  end


  def current_record
    @location_profile
  end


  def show
    @location_profile = JSONModel(:location_profile).find(params[:id])
  end


  def edit
    @location_profile = JSONModel(:location_profile).find(params[:id])
  end


  def create
    handle_crud(:instance => :location_profile,
                :model => JSONModel(:location_profile),
                :on_invalid => ->() {
                  return render_aspace_partial :partial => "location_profiles/new" if inline?
                  return render :action => :new
                },
                :on_valid => ->(id) {
                  if inline?
                    @location_profile.refetch
                    render :json => @location_profile.to_hash if inline?
                  else
                    flash[:success] = t("location_profile._frontend.messages.created")
                    return redirect_to :controller => :location_profiles, :action => :new if params.has_key?(:plus_one)
                    redirect_to(:controller => :location_profiles, :action => :show, :id => id)
                  end
                })
  end


  def update
    handle_crud(:instance => :location_profile,
                :model => JSONModel(:location_profile),
                :obj => JSONModel(:location_profile).find(params[:id]),
                :replace => true,
                :on_invalid => ->() {
                  return render :action => :edit
                },
                :on_valid => ->(id) {
                  redirect_to(:controller => :location_profiles, :action => :show, :id => id)
                })
  end


  def delete
    location_profile = JSONModel(:location_profile).find(params[:id])
    location_profile.delete

    redirect_to(:controller => :location_profiles, :action => :index, :deleted_uri => location_profile.uri)
  end


  def typeahead
    render :json => Search.all(session[:repo_id], params_for_backend_search)
  end


end
