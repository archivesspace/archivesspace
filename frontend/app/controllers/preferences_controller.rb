class PreferencesController < ApplicationController

  set_access_control  "view_repository" => [:edit, :update]

  def edit
    if params['id'] == "0"
      @search_data = JSONModel(:preference).all(:user_id => JSONModel(:user).id_for(session[:user_uri]))
      
      if @search_data.length == 1
        pref = @search_data.first
      elsif @search_data.length == 0
        # create a record
        pref = JSONModel(:preference).new({
                                :defaults => '{}',
                                :user_id => JSONModel(:user).id_for(session[:user_uri])
                              })
        pref.save
      else
        # problem
      end
      redirect_to(:controller => :preferences, :action => :edit, :id => pref.id)
    else
      @preference = JSONModel(:preference).find(params['id'])
    end
    
  end


  def update
    params['preference']['defaults'] = JSONModel(:defaults).from_hash(eval(params['preference']['defaults']))
    handle_crud(:instance => :preference,
                :model => JSONModel(:preference),
                :obj => JSONModel(:preference).find(params['id']),
                :replace => false,
                :on_invalid => ->(){
                  return render action: "edit"
                },
                :on_valid => ->(id){
                  flash[:success] = I18n.t("preference._frontend.messages.updated", JSONModelI18nWrapper.new(:preference => @preference))
                  redirect_to :controller => :preferences, :action => :edit, :id => id
                })
  end

end
