class PreferencesController < ApplicationController

  set_access_control  "view_repository" => [:edit, :update]

  def edit
    scope = params['global'] ? 'global' : 'repo'
    @current_prefs, global_repo_id = current_preferences
    @defaults = @current_prefs['defaults']
    opts = {}
    if params['global']
      opts[:repo_id] = global_repo_id
    end

    if @current_prefs["user_#{scope}"]
      pref = JSONModel(:preference).from_hash(@current_prefs["user_#{scope}"])
    else
      pref = JSONModel(:preference).new({
                                          :defaults => {},
                                          :user_id => JSONModel(:user).id_for(session[:user_uri])
                                        })
      pref.save(opts)
    end

    if params['id'] == pref.id.to_s
      @preference = pref
    else
      redirect_to(:controller => :preferences, :action => :edit, :id => pref.id, :global => params['global'])
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
                :on_invalid => ->(){
                  return render action: "edit"
                },
                :on_valid => ->(id){
                  flash[:success] = I18n.t("preference._frontend.messages.updated",
                                           JSONModelI18nWrapper.new(:preference => @preference))
                  redirect_to :controller => :preferences, :action => :edit, :id => id, :global => params['global']
                })
  end


  private

  def current_preferences
    current_prefs = JSONModel::HTTP::get_json("/repositories/#{session[:repo_id]}/current_preferences")
    repo_id = JSONModel(:repository).id_for(current_prefs['global']['repository']['ref'])
    
    return current_prefs, repo_id
  end

end
