class ApplicationController < ActionController::Base
  protect_from_forgery

  helper :all

  rescue_from ArchivesSpace::SessionGone, :with => :destroy_user_session


  # Note: This should be first!
  before_filter :store_user_session

  before_filter :load_repository_list
  before_filter :load_default_vocabulary

  protected

  def inline?
    params[:inline] === "true"
  end


  # Perform the common create/update logic for our various CRUD controllers:
  #
  #  * Take user parameters and massage them a bit
  #  * Grab the existing instance of our JSONModel
  #  * Update it from the parameters
  #  * If all looks good, send the user off to their next adventure
  #  * Otherwise, throw the form back with warnings/errors
  #
  def handle_crud(opts)
    begin
      # The UI may pass JSON blobs for linked resources for the purposes of displaying its form.
      # Deserialise these so the corresponding objects are stored on the JSONModel.
      (params[opts[:instance]]["resolved"] or []).each do |property, value|
        values =  value.collect {|json| JSON(json) if json and not json.empty?}.reject {|e| e.nil?}
        params[opts[:instance]]["resolved"][property] = values
      end

      # Start with the JSONModel object provided, or an empty one if none was
      # given.  Update it from the user's parameters
      model = opts[:model] || JSONModel(opts[:instance])
      obj = opts[:obj] || model.new
      obj.replace(params[opts[:instance]])

      # Make the updated object available to templates
      instance_variable_set("@#{opts[:instance]}".intern, obj)

      if not params.has_key?(:ignorewarnings) and not obj._warnings.empty?
        # Throw the form back to the user to confirm warnings.
        return opts[:on_invalid].call
      end

      id = obj.save
      opts[:on_valid].call(id)
    rescue JSONModel::ValidationException => e
      # Throw the form back to the user to display error messages.
      opts[:on_invalid].call
    end
  end


  private

  def destroy_user_session
    Thread.current[:backend_session] = nil
    Thread.current[:repo_id] = nil

    reset_session

    flash[:error] = "Your backend session was not found"
    redirect_to :controller => :welcome, :action => :index
  end


  def store_user_session
    Thread.current[:backend_session] = session[:session]
    Thread.current[:selected_repo_id] = session[:repo_id]
  end


  def load_repository_list
    @repositories = JSONModel(:repository).all

    if not session.has_key?(:repo) and not @repositories.empty?
      session[:repo] = @repositories.first.repo_code.to_s
      session[:repo_id] = @repositories.first.id
    end

  end

  def load_default_vocabulary
    if not session.has_key?(:vocabulary)
      session[:vocabulary] = JSONModel(:vocabulary).all.first.to_hash
    end
  end

  def choose_layout
    if inline?
      nil
    else
      'application'
    end
  end

end
