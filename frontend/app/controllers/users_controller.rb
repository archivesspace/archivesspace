class UsersController < ApplicationController
  skip_before_filter :unauthorised_access
  

  def index

    if session['user'] && !user_can?('create_user')
      redirect_to :controller => :welcome, :action => :index
    else
      @search_data = JSONModel(:user).all(:page => selected_page)
    end
  end
  
  def show
    
    @user = JSONModel(:user).find(params[:id])
    return render action: "show"  
  end

  def new 
    @user = JSONModel(:user).new._always_valid!

    return render action: "new"
  end

  def edit
    if !user_can?('create_user')
      return redirect_to :controller => :welcome, :action => :index
    end
      
    username = params[:username] || params[:id] # I'm not sure why 

    @user = JSONModel(:user).find(username)    
    return render action: "edit"
  end
  
  def update

    handle_crud(:instance => :user,
                :obj => JSONModel(:user).find(params[:username]),
                :params_check => ->(obj, params){
                  if params['user']['password'] || params['user']['confirm_password']
                    if params['user']['password'] != params['user']['confirm_password']
                      obj.add_error('confirm_password', "entered value didn't match password")
                    end
                  end
                },
                :on_invalid => ->(){
                  flash[:error] = "User not saved"
                  render :action => "edit"
                },
                :on_valid => ->(id){
                  flash[:success] = "User Saved"
                  redirect_to :action => :index
                })
  end  


  def create
    
    handle_crud(:instance => :user,
                :params_check => ->(obj, params){
                  
                  ['password', 'confirm_password'].each do |field|
                    if params['user'][field].blank?
                      obj.add_error(field, "Can't be empty")
                    end
                  end
                  if params['user']['password'] != params['user']['confirm_password']
                    obj.add_error('confirm_password', "entered value didn't match password")
                  end
                },
                :on_invalid => ->(){
                  flash[:error] = "User not saved"
                  render :action => "new"
                },
                :on_valid => ->(id){
                  
                  if session[:user]
                    flash[:success] = "Created user #{params['user']['username']}"
                    redirect_to :controller => :users, :action => :index
                  else
                    backend_session = User.login(params['user']['username'],
                                               params['user']['password'])

                    User.establish_session(session, backend_session, params['user']['username'])

                    redirect_to :controller => :welcome, :action => :index

                  end
                  
                })
  end
end
