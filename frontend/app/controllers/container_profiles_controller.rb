class ContainerProfilesController < ApplicationController

  set_access_control  "view_repository" => [:show, :index, :typeahead],
                      "update_container_profile_record" => [:new, :edit, :create, :update, :delete],
                      "manage_repository" => [:defaults, :update_defaults]

  include ExportHelper

  def new
    @container_profile = JSONModel(:container_profile).new._always_valid!

    defaults = user_defaults('container_profile')
    @container_profile.update(defaults.values) if defaults

    render_aspace_partial :partial => "container_profiles/new" if inline?
  end


  def index
    respond_to do |format|
      format.html {
        @search_data = Search.for_type(session[:repo_id], "container_profile", params_for_backend_search.merge({"facet[]" => SearchResultData.CONTAINER_PROFILE_FACETS}))
      }
      format.csv {
        search_params = params_for_backend_search.merge({"facet[]" => SearchResultData.CONTAINER_PROFILE_FACETS})
        search_params["type[]"] = "container_profile"
        uri = "/repositories/#{session[:repo_id]}/search"
        csv_response( uri, Search.build_filters(search_params), "#{t('container_profile._plural').downcase}." )
      }
    end
  end

  def current_record
    @container_profile
  end

  def show
    @container_profile = JSONModel(:container_profile).find(params[:id])
  end


  def edit
    @container_profile = JSONModel(:container_profile).find(params[:id])
  end


  def create
    handle_crud(:instance => :container_profile,
                :model => JSONModel(:container_profile),
                :on_invalid => ->() {
                  return render_aspace_partial :partial => "container_profiles/new" if inline?
                  return render :action => :new
                },
                :on_valid => ->(id) {
                  if inline?
                    @container_profile.refetch
                    render :json => @container_profile.to_hash if inline?
                  else
                    flash[:success] = t("container_profile._frontend.messages.created")
                    return redirect_to :controller => :container_profiles, :action => :new if params.has_key?(:plus_one)
                    redirect_to(:controller => :container_profiles, :action => :show, :id => id)
                  end
                })
  end


  def update
    handle_crud(:instance => :container_profile,
                :model => JSONModel(:container_profile),
                :obj => JSONModel(:container_profile).find(params[:id]),
                :replace => true,
                :on_invalid => ->() {
                  return render :action => :edit
                },
                :on_valid => ->(id) {
                  redirect_to(:controller => :container_profiles, :action => :show, :id => id)
                })
  end


  def delete
    container_profile = JSONModel(:container_profile).find(params[:id])
    container_profile.delete

    redirect_to(:controller => :container_profiles, :action => :index, :deleted_uri => container_profile.uri)
  end


  def typeahead
    search_params = params_for_backend_search

    search_params = search_params.merge("sort" => "typeahead_sort_key_u_sort asc")

    render :json => Search.all(session[:repo_id], search_params)
  end

  def defaults
    defaults = DefaultValues.get 'container_profile'

    values = defaults ? defaults.form_values : {}

    @container_profile = JSONModel(:container_profile).new(values)._always_valid!
    @form_title = t("default_values.form_title.container_profile")

    render "defaults"
  end

  def update_defaults
    begin
      DefaultValues.from_hash({
                                "record_type" => "container_profile",
                                "lock_version" => params[:container_profile].delete('lock_version'),
                                "defaults" => cleanup_params_for_schema(
                                                                        params[:container_profile],
                                                                        JSONModel(:container_profile).schema)
                              }).save

      flash[:success] = t("default_values.messages.defaults_updated")
      redirect_to :controller => :container_profiles, :action => :defaults
    rescue Exception => e
      flash[:error] = e.message
      redirect_to :controller => :container_profiles, :action => :defaults
    end
  end


end
