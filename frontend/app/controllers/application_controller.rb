require 'asconstants'
require 'memoryleak'
require 'search'

class ApplicationController < ActionController::Base
  protect_from_forgery

  helper :all

  rescue_from ArchivesSpace::SessionGone, :with => :destroy_user_session
  rescue_from ArchivesSpace::SessionExpired, :with => :destroy_user_session
  rescue_from RecordNotFound, :with => :render_404

  # Allow overriding of templates via the local folder(s)
  if not ASUtils.find_local_directories.blank?
    ASUtils.find_local_directories.map{|local_dir| File.join(local_dir, 'frontend', 'views')}.reject { |dir| !Dir.exists?(dir) }.each do |template_override_directory|
      prepend_view_path(template_override_directory)
    end
  end

  before_filter :determine_browser_support

  # Note: This should be first!
  before_filter :store_user_session

  before_filter :refresh_permissions

  before_filter :load_repository_list

  before_filter :unauthorised_access

  before_filter :sanitize_params

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
      # Start with the JSONModel object provided, or an empty one if none was
      # given.  Update it from the user's parameters
      model = opts[:model] || JSONModel(opts[:instance])
      obj = opts[:obj] || model.new

      obj.instance_data[:find_opts] = opts[:find_opts] if opts.has_key? :find_opts

      # Param validations that don't have to do with the JSON validator
      opts[:params_check].call(obj, params) if opts[:params_check]

      instance = cleanup_params_for_schema(params[opts[:instance]], model.schema)

      if opts[:replace] || opts[:replace].nil?
        obj.replace(instance)
      else
        obj.update(instance)
      end

      # Make the updated object available to templates
      instance_variable_set("@#{opts[:instance]}".intern, obj)

      if not params.has_key?(:ignorewarnings) and not obj._warnings.empty?
        # Throw the form back to the user to confirm warnings.
        instance_variable_set("@exceptions".intern, obj._exceptions)
        return opts[:on_invalid].call
      end

      if obj._exceptions[:errors]
        instance_variable_set("@exceptions".intern, obj._exceptions)
        return opts[:on_invalid].call
      end

      if opts.has_key?(:save_opts)
        id = obj.save(opts[:save_opts])
      elsif opts[:instance] == :user and !params['user']['password'].blank?
        id = obj.save(:password => params['user']['password'])
      else
        id = obj.save
      end
      opts[:on_valid].call(id)
    rescue ConflictException
      instance_variable_set(:"@record_is_stale".intern, true)
      opts[:on_invalid].call
    rescue JSONModel::ValidationException => e
      # Throw the form back to the user to display error messages.
      instance_variable_set("@exceptions".intern, obj._exceptions)
      opts[:on_invalid].call
    end
  end


  def handle_merge(victim_uri, target_uri, merge_type, extra_params = {})
    request = JSONModel(:merge_request).new
    request.target = {'ref' => target_uri}
    request.victims = [{'ref' => victim_uri}]

    begin
      request.save(:record_type => merge_type)
      flash[:success] = I18n.t("#{merge_type}._frontend.messages.merged")

      resolver = Resolver.new(target_uri)
      redirect_to(resolver.view_uri)
    rescue ValidationException => e
      flash[:error] = e.errors
      redirect_to({:action => :show, :id => params[:id]}.merge(extra_params))
    rescue RecordNotFound => e
      flash[:error] = I18n.t("errors.error_404")
      redirect_to({:action => :show, :id => params[:id]}.merge(extra_params))
    end
  end


  def handle_accept_children(target_jsonmodel)
    response = JSONModel::HTTP.post_form(target_jsonmodel.uri_for(params[:id]) + "/accept_children",
                                         "children[]" => params[:children],
                                         "position" => params[:index].to_i)

    if response.code == '200'
      render :json => {
        :parent => params[:id],
        :position => params[:index].to_i
      }
    else
      raise "Error setting parent of archival objects: #{response.body}"
    end
  end


  def selected_page
    if params["page"]
      page = Integer(params["page"])
      if page < 0
        raise "Invalid page value"
      end

      page
    else
      # Default to showing the first page
      1
    end
  end


  def user_must_have(permission)
    render_403 if !session['user'] || !user_can?(permission)
  end


  def user_needs_to_be_a_user
    render_403 if not session['user']
  end
  
  def user_needs_to_be_a_user_manager
    render_403 if not user_can? 'manage_users'
  end
  
  def user_needs_to_be_a_user_manager_or_new_user
    render_403 if session['user'] and not user_can? 'manage_users'
  end


  helper_method :user_can?
  def user_can?(permission, repository = nil)
    repository ||= session[:repo]

    (session &&
     session[:user] &&
     session[:permissions] &&

     (session[:permissions][repository] &&
      session[:permissions][repository].include?(permission) ||

      (session[:permissions][ASConstants::Group.GLOBAL] &&
       session[:permissions][ASConstants::Group.GLOBAL].include?(permission))))
  end

  helper_method :current_vocabulary
  def current_vocabulary
    MemoryLeak::Resources.get(:vocabulary).first.to_hash
  end


  private

  def destroy_user_session(exception)
    Thread.current[:backend_session] = nil
    Thread.current[:repo_id] = nil

    reset_session

    @message = exception.message
    return render :template => "401", :layout => nil if inline?

    flash[:error] = exception.message
    redirect_to :controller => :welcome, :action => :index, :login => true
  end


  def store_user_session
    Thread.current[:backend_session] = session[:session]
    Thread.current[:selected_repo_id] = session[:repo_id]
  end


  def load_repository_list
    @repositories = MemoryLeak::Resources.get(:repository).find_all do |repository|
      user_can?('view_repository', repository.uri) || user_can?('manage_repository', repository.uri)
    end

    # Make sure the user's selected repository still exists.
    if session[:repo] && !@repositories.any?{|repo| repo.uri == session[:repo]}
      session.delete(:repo)
      session.delete(:repo_id)
    end

    if not session[:repo] and not @repositories.empty?
      session[:repo] = @repositories.first.uri
      session[:repo_id] = @repositories.first.id
    end
  end


  def refresh_permissions
    if session[:last_permission_refresh] &&
        session[:last_permission_refresh] < MemoryLeak::Resources.get(:acl_system_mtime)
      User.refresh_permissions(session)
    end
  end


  def choose_layout
    if inline?
      nil
    else
      'application'
    end
  end


  def sanitize_param(hash)
    hash.clone.each do |k,v|
      hash[k.sub("_attributes","")] = v if k.end_with?("_attributes")
      sanitize_param(v) if v.kind_of? Hash
    end
  end


  def sanitize_params
    sanitize_param(params)
  end


  def unauthorised_access
    render_403
  end


  def account_self_service
    if !AppConfig[:allow_user_registration] && session[:user].nil?
      render_403
    end
  end

  def render_403
    return render :template => "403", :layout => nil if inline?

    render "/403"
  end


  def render_404
    return render :template => "404", :layout => nil if inline?

    render "/404"
  end


  def determine_browser_support
    if session[:browser_support]
      @browser_support = session[:browser_support].intern
      return
    end

    user_agent = UserAgent.parse(request.user_agent)

    @browser_support = :unknown
    if BrowserSupport.bronze.detect {|browser| user_agent <= browser}
      @browser_support = :bronze
    elsif BrowserSupport.silver.detect {|browser| user_agent <= browser}
      @browser_support = :silver
    elsif BrowserSupport.silver.detect {|browser| user_agent > browser} || BrowserSupport.gold.detect {|browser| user_agent >= browser}
      @browser_support = :gold
    end

    session[:browser_support] = @browser_support
  end

  protected

  def cleanup_params_for_schema(params_hash, schema)
    fix_arrays = proc do |hash, schema|
      result = hash.clone

      schema['properties'].each do |property, definition|
        if definition['type'] == 'array' && result[property].is_a?(Hash)
          result[property] = result[property].map {|_, v| v}
        end
      end

      result
    end


    set_false_for_checkboxes = proc do |hash, schema|
      result = hash.clone

      schema['properties'].each do |property, definition|
        if definition['type'] == 'boolean'
          if not result.has_key?(property)
            result[property] = false
          else
            result[property] = (result[property].to_i === 1)
          end
        end
      end

      result
    end


    coerce_integers = proc do |hash, schema|

      schema['properties'].each do |property, definition|
        if definition['type'] == 'integer'
          if hash.has_key?(property) && hash[property].is_a?(String)
            if (i = hash[property].to_i) && i > 0
              hash[property] = i
            end
          end
        end
      end

      hash
    end


    deserialise_resolved_json_blobs = proc do |hash, schema|
      # The linker widget sends us the full blob of each record being linked
      # to as a JSON blob.  Make this available as a regular hash by walking
      # the document and deserialising these blobs.

      if hash.has_key?('_resolved') && hash['_resolved'].is_a?(String)
        hash.merge('_resolved' => ASUtils.json_parse(hash['_resolved']))
      else
        hash
      end
    end


    JSONSchemaUtils.map_hash_with_schema(params_hash,
                                         schema,
                                         [fix_arrays,
                                          set_false_for_checkboxes,
                                          deserialise_resolved_json_blobs,
                                          coerce_integers])
  end

  def search_params
    params_for_search = params.select{|k,v| ["page", "q", "type", "sort", "exclude", "filter_term"].include?(k) and not v.blank?}

    params_for_search["page"] ||= 1

    if params_for_search["type"]
      params_for_search["type[]"] = Array(params_for_search["type"]).reject{|v| v.blank?}
      params_for_search.delete("type")
    end

    if params_for_search["filter_term"]
      params_for_search["filter_term[]"] = Array(params_for_search["filter_term"]).reject{|v| v.blank?}
      params_for_search.delete("filter_term")
    end

    if params_for_search["exclude"]
      params_for_search["exclude[]"] = Array(params_for_search["exclude"]).reject{|v| v.blank?}
      params_for_search.delete("exclude")
    end

    params_for_search
  end

  def parse_tree(node, parent, proc)
    node['children'].map{|child_node| parse_tree(child_node, node, proc)} if node['children']
    proc.call(node, parent)
  end


  def handle_transfer(model)
    old_uri = model.uri_for(params[:id])
    response = JSONModel::HTTP.post_form(model.uri_for(params[:id]) + "/transfer",
                                         "target_repo" => params[:ref])

    if response.code == '200'
      flash[:success] = I18n.t("actions.transfer_successful")
    else
      flash[:error] = I18n.t("actions.transfer_failed") + ": " + response.body
    end

    redirect_to(:action => :index, :deleted_uri => old_uri)
  end

end
