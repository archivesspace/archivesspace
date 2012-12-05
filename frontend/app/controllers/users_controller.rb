class UsersController < ApplicationController
  skip_before_filter :unauthorised_access

  def index

    if session['user'] && !user_can?('create_user')
      redirect_to :controller => :welcome, :action => :index
    else
      @user = JSONModel(:user).new._always_valid!

      return render action: "new"
    end
  end


  def create
    
    @user = JSONModel(:user).from_hash(params['user'])

    ['password', 'confirm_password'].each do |field|
      if not params['user'][field] or params['user'][field].empty?
        @user.add_error(field, "Can't be empty")
      end
    end

    if not @user._exceptions[:errors] and
        params['user']['password'] != params['user']['confirm_password']
      @user.add_error('confirm_password', "entered value didn't match password")
    end

    if @user._exceptions[:errors]
      @exceptions = @user._exceptions
      return render :action => "new"
    end

    @user.save(:password => params['user']['password'])

    if session[:user]
      flash[:success] = "Created user #{params['user']['username']}"
      redirect_to :controller => :users, :action => :create
    else
      backend_session = User.login(params['user']['username'],
                                 params['user']['password'])

      User.establish_session(session, backend_session, params['user']['username'])

      redirect_to :controller => :welcome, :action => :index

    end



  rescue JSONModel::ValidationException => e
    @user = e.invalid_object
    @exceptions = @user._exceptions
    render :action => "new"
  end

end
