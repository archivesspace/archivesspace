class PreferencesController < ApplicationController

  set_access_control "view_repository" => [:edit, :update, :reset]

  def edit
    opts, user_scope = setup_defaults

    if @current_prefs[user_scope]
      pref = JSONModel(:preference).from_hash(@current_prefs[user_scope])
    else
      pref = JSONModel(:preference).new({
                                          :defaults => {},
                                          :user_id => params['repo'] ? nil : JSONModel(:user).id_for(session[:user_uri])
                                        })
      pref.save(opts)
    end

    if params['id'] == pref.id.to_s
      @preference = pref
    else
      redirect_to(:controller => :preferences,
                  :action => :edit,
                  :id => pref.id,
                  :global => params['global'],
                  :repo => params['repo'])
    end
  end


  def update
    prefs, global_repo_id = current_preferences
    opts = {}
    opts[:repo_id] = global_repo_id if params['global']

    handle_crud(:instance => :preference,
                :model => JSONModel(:preference),
                :obj => JSONModel(:preference).find(params['id'], opts),
                :find_opts => opts,
                :save_opts => opts,
                :replace => false,
                :on_invalid => ->() {
                  setup_defaults
                  return render action: "edit"
                },
                :on_valid => ->(id) {
                  flash[:success] = t("preference._frontend.messages.updated",
                                           **JSONModelI18nWrapper.new(:preference => @preference))
                  redirect_to(:controller => :preferences,
                              :action => :edit,
                              :id => id,
                              :global => params['global'],
                              :repo => params['repo'])
                })
  end


  def reset
    redirect_params = {
      :controller => :preferences,
      :action => :edit,
      :id => 0,
      :global => params['global'],
      :repo => params['repo']
    }

    begin
      _, global_repo_id = current_preferences
      opts = {}
      opts[:repo_id] = global_repo_id if params['global']
      preference = JSONModel(:preference).find(params[:id], opts)
      preference.update({:defaults => {}})
      preference.save(opts)

      flash[:success] = t("preference._frontend.messages.reset")
      redirect_to(redirect_params)
    rescue Exception => e
      flash[:error] = t("preference._frontend.messages.reset_error", :exception => e)
      redirect_to(redirect_params)
      return
    end
  end


  private

  def current_preferences
    if session[:repo_id]
      current_prefs = JSONModel::HTTP::get_json("/repositories/#{session[:repo_id]}/current_preferences")
    else
      current_prefs = JSONModel::HTTP::get_json("/current_global_preferences")
    end

    global_repo_id = JSONModel(:repository).id_for(current_prefs['global']['repository']['ref'])

    return current_prefs, global_repo_id
  end

  def setup_defaults
    scope = params['global'] ? 'global' : 'repo'
    user_prefix = params['repo'] ? '' : 'user_'
    @current_prefs, global_repo_id = current_preferences
    @defaults = @current_prefs['defaults']
    level = "#{user_prefix}#{scope}"
    @inherited_defaults = @current_prefs["defaults_global"]
    ['user_global', 'repo', 'user_repo'].each do |lev|
      break if lev == level
      @inherited_defaults = @current_prefs["defaults_#{lev}"] if @current_prefs["defaults_#{lev}"]
    end

    opts = {}
    opts[:repo_id] = global_repo_id if params['global']

    return opts, level
  end

end
