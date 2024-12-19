require 'asconstants'
require 'memoryleak'
require 'search'
require 'zlib'

class ApplicationController < ActionController::Base
  include ActionView::Helpers::TranslationHelper
  protect_from_forgery with: :exception

  helper :all

  rescue_from ArchivesSpace::SessionGone, :with => :destroy_user_session
  rescue_from ArchivesSpace::SessionExpired, :with => :destroy_user_session
  rescue_from RecordNotFound, :with => :render_404
  rescue_from AccessDeniedException, :with => :render_403

  # Allow overriding of templates via the local folder(s)
  if not ASUtils.find_local_directories.blank?
    ASUtils.find_local_directories.map {|local_dir| File.join(local_dir, 'frontend', 'views')}.reject { |dir| !Dir.exist?(dir) }.each do |template_override_directory|
      prepend_view_path(template_override_directory)
    end
  end

  # Note: This should be first!
  before_action :store_user_session, unless: -> { params[:login] && !session[:user] }

  before_action :refresh_permissions, unless: -> { params[:login] && !session[:user] }

  before_action :refresh_preferences, unless: -> { params[:login] && !session[:user] }

  before_action :load_repository_list, unless: -> { params[:login] && !session[:user] }

  before_action :unauthorised_access

  before_action :init_ancestor_titles

  around_action :set_locale

  def self.permission_mappings
    Array(@permission_mappings)
  end

  def self.can_access?(context, method)
    permission_mappings.each do |permission, actions|
      if actions.include?(method) && !session_can?(context, permission)
        return false
      end
    end

    return true
  end


  def self.set_access_control(permission_mappings)
    @permission_mappings = permission_mappings

    skip_before_action :unauthorised_access, :only => Array(permission_mappings.values).flatten.uniq

    permission_mappings.each do |permission, actions|
      next if permission === :public

      before_action(:only => Array(actions)) {|c| user_must_have(permission)}
    end
  end

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

      # We need to retain any restricted properties from the existing object. i.e.
      # properties that exist for the record but the user was not allowed to edit
      unless params[:action] == 'copy'
        if params[opts[:instance]].key?(:restricted_properties)
          params[opts[:instance]][:restricted_properties].each do |restricted|
            next unless obj.has_key? restricted

            params[opts[:instance]][restricted] = obj[restricted].dup
          end
        end
      end

      # Param validations that don't have to do with the JSON validator
      opts[:params_check].call(obj, params) if opts[:params_check]

      instance = cleanup_params_for_schema(params[opts[:instance]], model.schema)

      if opts[:before_hooks]
        opts[:before_hooks].each { |hook| hook.call(instance) }
      end

      if opts[:replace] || opts[:replace].nil?
        obj.replace(instance)
      elsif opts[:copy]
        obj.name = "Copy of " + obj.name
        obj.uri = ''
      else
        obj.update(instance)
      end

      if opts[:required_fields]
        opts[:required_fields].add_errors(obj)
      end

      # Make the updated object available to templates
      instance_variable_set("@#{opts[:instance]}".intern, obj)

      if not params.has_key?(:ignorewarnings) and not obj._warnings.empty?
        # Throw the form back to the user to confirm warnings.
        instance_variable_set("@exceptions".intern, obj._exceptions)
        return opts[:on_invalid].call
      end

      if obj._exceptions[:errors]
        instance_variable_set("@exceptions".intern, clean_exceptions(obj._exceptions))
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


  def handle_merge(merge_candidates, merge_destination_uri, merge_type, extra_params = {})
    request = JSONModel(:merge_request).new
    request.merge_destination = {'ref' => merge_destination_uri}
    request.merge_candidates = Array.wrap(merge_candidates).map { |merge_candidate| { 'ref' => merge_candidate } }
    if params[:id]
      id = params[:id]
    else
      id = merge_destination_uri.split('/')[-1]
    end
    begin
      request.save(:record_type => merge_type)

      flash[:success] = t("#{merge_type}._frontend.messages.merged")

      if merge_type == 'top_container'
        redirect_to(:controller => :top_containers, :action => :index)
      else
        resolver = Resolver.new(merge_destination_uri)
        redirect_to(resolver.view_uri)
      end
    rescue ValidationException => e
      flash[:error] = e.errors.to_s
      redirect_to({:action => :show, :id => id}.merge(extra_params))
    rescue ConflictException => e
      flash[:error] = t("errors.merge_conflict", :message => e.conflicts)
      redirect_to({:action => :show, :id => id}.merge(extra_params))
    rescue RecordNotFound => e
      flash[:error] = t("errors.error_404")
      redirect_to({:action => :show, :id => id}.merge(extra_params))
    end
  end


  def handle_accept_children(merge_destination_jsonmodel)
    unless params[:children]
      # Nothing to do
      return render :json => {
                      :position => params[:index].to_i
                    }
    end

    response = JSONModel::HTTP.post_form(merge_destination_jsonmodel.uri_for(params[:id]) + "/accept_children",
                                         "children[]" => params[:children],
                                         "position" => params[:index].to_i)




    if response.code == '200'
      render :json => {
        :position => params[:index].to_i
      }
    else
      raise "Error setting parent of archival objects: #{response.body}"
    end
  end

  # could be generalized further by accepting related_type [ex: event] and related_field [ex: linked_record_uris]
  def fetch_linked_events_count(type, id)
    uri = JSONModel(type).uri_for(id)
    Search.for_type(session[:repo_id], "event", params_for_backend_search.merge(
      {"facet[]" => SearchResultData.EVENT_FACETS, "q" => "linked_record_uris:\"#{uri}\"", "fields[]" => "id"}
    ))['total_hits']
  end

  def fetch_resolved(type, id, excludes: [])
    # We add this so that we can get a top container location to display with the instance view
    new_find_opts = find_opts
    new_find_opts["resolve[]"].push("top_container::container_locations")
    new_find_opts["resolve[]"] = new_find_opts["resolve[]"] - excludes

    record = JSONModel(type).find(id, new_find_opts)

    if record['classifications']
      record['classifications'].each do |classification|
        next unless classification['_resolved']
        resolved = classification["_resolved"]
        resolved['title'] = ClassificationHelper.format_classification(resolved['path_from_root'])
      end
    end

    record
  end

  def find_opts
    {
      "resolve[]" => ["subjects", "related_resources", "linked_agents",
                      "revision_statements",
                      "container_locations", "digital_object", "classifications",
                      "related_agents", "resource", "parent", "creator",
                      "linked_instances", "linked_records", "related_accessions",
                      "linked_events", "linked_events::linked_records",
                      "linked_events::linked_agents",
                      "top_container", "container_profile", "location_profile",
                      "owner_repo", "places", "component_links", "accession_links"] + Plugins.fields_to_resolve
    }
  end

  def user_is_global_admin?
    if AppConfig[:allow_other_admins_access_to_system_info]
      session['user'] and user_can? 'administer_system'
    else
      session['user'] and session['user'] == "admin"
    end
  end


  def user_must_have(permission)
    unauthorised_access if !session['user'] || !user_can?(permission)
  end


  def user_needs_to_be_a_user
    unauthorised_access if not session['user']
  end

  def user_needs_to_be_a_user_manager
    unauthorised_access if not user_can? 'manage_users'
  end

  def user_needs_to_be_a_user_manager_or_new_user
    unauthorised_access if session['user'] and not user_can? 'manage_users'
  end

  def user_needs_to_be_global_admin
    unauthorised_access if not user_is_global_admin?
  end

  helper_method :user_prefs
  def user_prefs
    session[:preferences] || self.class.user_preferences(session)
  end

  def user_defaults(record_type)
    default_values = user_prefs['default_values']
    DefaultValues.get(record_type) if default_values
  end

  helper_method :browse_columns
  def browse_columns
    @browse_columns ||= if session[:repo_id]
                          JSONModel::HTTP::get_json("/repositories/#{session[:repo_id]}/current_preferences")['defaults']
                        else
                          JSONModel::HTTP::get_json("/current_global_preferences")['defaults']
                        end
  end

  def user_repository_cookie
    cookies[user_repository_cookie_key]
  end

  def user_repository_cookie_key
    "#{AppConfig[:cookie_prefix]}_#{session[:user]}_repository"
  end

  def set_user_repository_cookie(repository_uri)
    cookies[user_repository_cookie_key] = {
      value: repository_uri,
      httponly: true,
      same_site: :lax
    }
  end

  # sometimes we get exceptions that look like this: "translation missing: validation_errors.protected_read-only_list_#/dates_of_existence/0/date_type_structured._invalid_value__add_or_update_either_a_single_or_ranged_date_subrecord_to_set_.__must_be_one_of__single__range
  # replace the untranslatable text with a generic message
  # untranslatable messages have a reference to an array index, like record/0/subrecord. We'll look for anything that has an error that matches to /d+/ and replace it with something generic that we can translate.
  def clean_exceptions(ex)
    generic_error = t("validation_errors.generic_validation_error")
    regex = /\/\d+\//

    ex.each do |key, exception|
      exception.each do |key, value|
        # value might be a string or an array of strings
        if value.is_a?(String)
          if value =~ regex
            value = generic_error
          end
        elsif value.respond_to?(:each_with_index)
          value.each_with_index do |subvalue, i|
            if subvalue =~ regex
              value[i] = generic_error
            end
          end
        end
      end
    end

    return ex
  end


  # ANW-617: To generate public URLs correctly in the show pages for various entities, we need access to the repository slug.
  # Since the JSON objects for these does not have this info, we load it into the session along with other repo data when a repo is selected for convienience.
  def self.session_repo(session, repo, repo_slug = nil)
    session[:repo] = repo
    session[:repo_id] = JSONModel(:repository).id_for(repo)

    # if the slug has been passed in, we don't need to do a DB lookup.
    # if not, we go get it so links are generated correctly after login.
    if repo_slug
      session[:repo_slug] = repo_slug
    else
      full_repo_json = JSONModel(:repository).find(session[:repo_id])
      session[:repo_slug] = full_repo_json[:slug]
    end

    self.user_preferences(session)
  end


  def self.user_preferences(session)
    session[:last_preference_refresh] = Time.now.to_i
    prefs = if session[:repo_id]
              JSONModel::HTTP::get_json("/repositories/#{session[:repo_id]}/current_preferences")['defaults']
            else
              JSONModel::HTTP::get_json("/current_global_preferences")['defaults']
            end
    session[:preferences] = prefs.reject { |k, _v|
      k.include? 'browse_column' or k.include? 'sort_column' or k.include? 'sort_direction'} if prefs
  end


  helper_method :user_can?
  def user_can?(permission, repository = nil)
    self.class.session_can?(self, permission, repository)
  end


  def self.session_can?(context, permission, repository = nil)
    repository ||= context.session[:repo]

    return false if !context.session || !context.session[:user]

    permissions_s = context.send(:cookies).signed[:archivesspace_permissions]

    if permissions_s
      # Putting this check in for backwards compatibility with the uncompressed
      # cookies.  This can be removed at a future point once everyone's running
      # with compressed cookies.
      json = if permissions_s.start_with?('ZLIB:')
               Zlib::Inflate.inflate(permissions_s[5..-1])
             else
               permissions_s
             end

      permissions = ASUtils.json_parse(json)
    else
      return false
    end

    (Permissions.user_can?(permissions, repository, permission) ||
     Permissions.user_can?(permissions, ASConstants::Repository.GLOBAL, permission))
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
    JSONModel::set_repository(session[:repo_id])
  end


  def load_repository_list
    @repositories = MemoryLeak::Resources.get(:repository).find_all do |repository|
      user_can?('view_repository', repository.uri) || user_can?('manage_repository', repository.uri)
    end

    # Make sure the user's selected repository still exists.
    if session[:repo] && !@repositories.any? {|repo| repo.uri == session[:repo]}
      session.delete(:repo)
      session.delete(:repo_id)
    end

    if not session[:repo] and not @repositories.empty?
      if user_repository_cookie
        if @repositories.any? {|repo| repo.uri == user_repository_cookie}
          self.class.session_repo(session, user_repository_cookie)
        else
          # delete the cookie as the stored repository uri is no longer valid
          cookies.delete(user_repository_cookie_key)
        end
      else
        set_user_repository_cookie(@repositories.first.uri)
        self.class.session_repo(session, @repositories.first.uri)
      end
    end
  end


  def refresh_permissions
    if session[:last_permission_refresh] &&
        session[:last_permission_refresh] < MemoryLeak::Resources.get(:acl_system_mtime)

      User.refresh_permissions(self)
    end
  end


  def refresh_preferences
    if session[:last_preference_refresh] &&
        session[:last_preference_refresh] < MemoryLeak::Resources.get(:preferences_system_mtime)

      session[:preferences] = nil
    end
  end


  def unauthorised_access
    render_403
  end


  def account_self_service
    if !AppConfig[:allow_user_registration] && session[:user].nil?
      unauthorised_access
    end
  end

  def render_403
    return render :status => 403, :template => "403", :layout => nil if inline?

    render "/403", :status => 403
  end


  def render_404
    return render :template => "404", :layout => nil if inline?

    render "/404"
  end


  # We explicitly set the formats and handlers here to avoid the huge number of
  # stat() syscalls that Rails normally triggers when running in dev mode.
  #
  # It would have been nice to call this 'render_partial', but that name is
  # taken by the default controller.
  #
  def render_aspace_partial(args)
    defaults = {:formats => [:html], :handlers => [:erb]}
    return render(defaults.merge(args))
  end


  def init_ancestor_titles
    @ancestor_titles = {}
  end


  protected

  def cleanup_params_for_schema(params_hash, schema)
    # We're expecting a HashWithIndifferentAccess...
    if params_hash.respond_to?(:to_unsafe_hash)
      params_hash = params_hash.to_unsafe_hash
    end

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
            result[property] = (result[property].respond_to?(:to_i) && result[property].to_i === 1)
          end
        end
      end

      result
    end


    coerce_integers = proc do |hash, schema|

      schema['properties'].each do |property, definition|
        if definition['type'] == 'integer'
          if hash.has_key?(property) && hash[property].is_a?(String)
            begin
              value = Integer(hash[property])
              if value >= 0 # exclude negative numbers for legacy reasons
                hash[property] = value
              end
            rescue ArgumentError
            end
          end
        end
      end

      hash
    end


    expand_multiple_item_linker_values = proc do |hash, schema|
      # The linker widget allows multiple items to be selected for some
      # associations.  In these cases, split up the values and create
      # separate records to be created.

      associations_to_expand = ['linked_agents', 'subjects', 'classifications']

      associations_to_expand.each do |association|
        if hash.has_key?(association)
          all_expanded = []

          hash[association].each do |linked_agent|
            if linked_agent.has_key?('ref') && linked_agent['ref'].is_a?(Array)
              linked_agent['ref'].each_with_index do |ref, i|
                expanded = linked_agent.clone
                expanded['ref'] = ref
                expanded['_resolved'] = linked_agent['_resolved'][i]
                all_expanded.push(expanded)
              end
            else
              all_expanded.push(linked_agent)
            end
          end

          hash[association] = all_expanded
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
                                          coerce_integers,
                                          expand_multiple_item_linker_values])
  end

  def params_for_backend_search
    backend_search_params = ["page", "q", "aq", "type", "sort", "exclude", "filter_term", "fields"]
    params_for_search = params.select {|k, v| backend_search_params.include?(k) and not v.blank?}

    params_for_search["page"] ||= 1

    if params_for_search["type"]
      params_for_search["type[]"] = Array(params_for_search["type"]).reject {|v| v.blank?}.uniq
      params_for_search.delete("type")
    end

    if params_for_search["filter_term"]
      params_for_search["filter_term[]"] = Array(params_for_search["filter_term"]).reject {|v| v.blank?}
      params_for_search.delete("filter_term")
    end

    if params_for_search["aq"]
      # Just validate it
      params_for_search["aq"] = JSONModel(:advanced_query).from_json(params_for_search["aq"]).to_json
    end

    if params_for_search["exclude"]
      params_for_search["exclude[]"] = Array(params_for_search["exclude"]).reject {|v| v.blank?}
      params_for_search.delete("exclude")
    end

    if params_for_search["fields"]
      params_for_search["fields[]"] = Array(params_for_search["fields"]).reject {|v| v.blank?}
      params_for_search.delete("fields")
    end

    params_for_search
  end

  def parse_tree(node, parent, &block)
    node['children'].map {|child_node| parse_tree(child_node, node, &block)} if node['children']
    block.call(node, parent)
  end


  def prepare_tree_nodes(node, &block)
    node['children'].map {|child_node| prepare_tree_nodes(child_node, &block) }
    block.call(node)
  end


  def handle_transfer(model)
    old_uri = model.uri_for(params[:id])

    response = JSONModel::HTTP.post_form(model.uri_for(params[:id]) + "/transfer", "target_repo" => params[:ref])

    if response.code == '200'
      flash[:success] = t("actions.transfer_successful")
    elsif response.code == '409'
    # Transfer failed for a known reason
      raise ArchivesSpace::TransferConflictException.new(ASUtils.json_parse(response.body).fetch('error'))
    else
      flash[:error] = t("actions.transfer_failed") + ": " + response.body
    end

    redirect_to(:action => :index, :deleted_uri => old_uri)
  end


  helper_method :default_advanced_search_queries
  def default_advanced_search_queries
    [{"i" => 0, "type" => "text", "comparator" => "contains"}]
  end


  helper_method :advanced_search_queries
  def advanced_search_queries
    return default_advanced_search_queries if !params["advanced"]

    indexes = params.keys.collect {|k| k[/^f(?<index>[\d]+)/, "index"]}.compact.sort {|a, b| a.to_i <=> b.to_i}

    return default_advanced_search_queries if indexes.empty?

    indexes.map {|i|
      query = {
        "i" => i.to_i,
        "op" => params["op#{i}"],
        "field" => params["f#{i}"],
        "value" => params["v#{i}"],
        "type" => params["t#{i}"]
      }

      if query["type"] == "text"
        query["comparator"] = params["top#{i}"]
        query["empty"] = query["comparator"] == "empty"
      end

      if query["op"] === "NOT"
        query["op"] = "AND"
        query["negated"] = true
      end

      if query["type"] == "date"
        query["comparator"] = params["dop#{i}"]
        query["empty"] = query["comparator"] == "empty"
      end

      if query["type"] == "boolean"
        query["value"] = query["value"] == "empty" ? "empty" : query["value"] == "true"
        query["empty"] = query["value"] == "empty"
      end

      if query["type"] == "enum"
        query["empty"] = query["value"].blank?
      end

      query
    }
  end

  def set_locale(&action)
    if session['user']
      locale = user_prefs.key?('locale') ? user_prefs['locale'].to_sym : I18n.default_locale
    else
      locale = I18n.default_locale
    end
    I18n.with_locale(locale, &action)
  end

  def current_record
    raise "method 'current_record' not implemented for controller: #{self}"
  end

  def controller_supports_current_record?
    self.method(:current_record).owner != ApplicationController
  end

  def check_required_subrecords(required, obj)
    required.each do |subrecord_field, requirements_defn|
      next unless requirements_defn.is_a?(Array)
      if obj[subrecord_field].empty?
        obj.add_error(subrecord_field, :missing_required_subrecord)
      end
    end
  end

  helper_method :current_record
  helper_method :'controller_supports_current_record?'
end
