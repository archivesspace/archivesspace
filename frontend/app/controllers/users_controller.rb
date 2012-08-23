class UsersController < ApplicationController

  def index
    @user = JSONModel(:user).new._always_valid!

    return render action: "new"
  end


  def create
    @user = JSONModel(:user).from_hash(params['createuser'])

    ['password', 'confirm_password'].each do |field|
      if not params['createuser'][field] or params['createuser'][field].empty?
        @user.add_error(field, "Can't be empty")
      end
    end

    if not @user._exceptions[:errors] and
        params['createuser']['password'] != params['createuser']['confirm_password']
      @user.add_error('passwords', "entered values didn't match")
    end

    if @user._exceptions[:errors]
      return render action: "new"
    end

    @user.save(:password => params['createuser']['password'])

    backend_session = User.login(params['createuser']['username'],
                                 params['createuser']['password'])

    User.establish_session(session, backend_session, params['createuser']['username'])

    redirect_to :controller=>:welcome, :action=>:index

  rescue JSONModel::ValidationException => e
    @user = e.invalid_object

    render action: "new", :notice=>"There was a problem creating your account"
  end

end
