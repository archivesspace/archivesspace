# frozen_string_literal: true

class AgentsController < ApplicationController
  set_access_control  'view_repository' => [:index, :show],
                      'update_agent_record' => [:new, :edit, :create, :update, :publish, :merge, :merge_selector, :merge_detail, :merge_preview],
                      'delete_agent_record' => [:delete],
                      'manage_repository' => [:defaults, :update_defaults, :required, :update_required]

  before_action :assign_types
  before_action :get_required, only: [:new, :create, :required]

  include ExportHelper

  def index
    respond_to do |format|
      format.html do
        @search_data = Search.for_type(session[:repo_id], 'agent', params_for_backend_search.merge({ 'facet[]' => SearchResultData.AGENT_FACETS }))
      end
      format.csv do
        search_params = params_for_backend_search.merge({ 'facet[]' => SearchResultData.AGENT_FACETS })
        search_params['type[]'] = 'agent'
        uri = "/repositories/#{session[:repo_id]}/search"
        csv_response(uri, Search.build_filters(search_params), "#{t('agent._plural').downcase}.")
      end
    end
  end

  def current_record
    @agent
  end

  def show
    @agent = JSONModel(@agent_type).find(params[:id], find_opts)
  end

  def new
    @agent = JSONModel(@agent_type).new({ agent_type: @agent_type })._always_valid!
    if user_prefs['default_values']
      defaults = DefaultValues.get @agent_type.to_s
      @agent.update(defaults.values) if defaults
    end

    @required_fields.each_required_subrecord do |property, stub_record|
      @agent[property] << stub_record if @agent[property].empty?
    end

    if @agent.names.empty?
      @agent.names = [@name_type.new({ authorized: true, is_display_name: true })._always_valid!]
    end

    ensure_auth_and_display

    set_sort_name_default

    render_aspace_partial partial: 'agents/new' if inline?
  end

  def edit
    @agent = JSONModel(@agent_type).find(params[:id], find_opts)
  end

  def create
    handle_crud(instance: :agent,
                model: JSONModel(@agent_type),
                required_fields: @required_fields,
                find_opts: find_opts,
                before_hooks: [method(:set_structured_date_type)],
                on_invalid: lambda {
                  ensure_auth_and_display
                  return render_aspace_partial partial: 'agents/new' if inline?
                  return render action: :new
                },
                on_valid: lambda  { |id|
                  flash[:success] = t('agent._frontend.messages.created')

                  if @agent['is_slug_auto'] == false &&
                     @agent['slug'].nil? &&
                     params['agent'] &&
                     params['agent']['is_slug_auto'] == '1'

                    flash[:warning] = t('slug.autogen_disabled')
                  end

                  return render json: @agent.to_hash if inline?
                  if params.key?(:plus_one)
                    return redirect_to({ controller: :agents, action: :new, agent_type: @agent_type })
                  end

                  redirect_to({ controller: :agents, action: :edit, id: id, agent_type: @agent_type })
                })
  end

  def update
    handle_crud(instance: :agent,
                model: JSONModel(@agent_type),
                obj: JSONModel(@agent_type).find(params[:id], find_opts),
                before_hooks: [method(:set_structured_date_type)],
                on_invalid: lambda {
                  if @agent.names.empty?
                    @agent.names = [@name_type.new._always_valid!]
                  end

                  return render action: :edit
                },
                on_valid: lambda  { |id|
                  flash[:success] = t('agent._frontend.messages.updated')
                  if @agent['is_slug_auto'] == false &&
                     @agent['slug'].nil? &&
                     params['agent'] &&
                     params['agent']['is_slug_auto'] == '1'

                    flash[:warning] = t('slug.autogen_disabled')
                  end

                  redirect_to controller: :agents, action: :edit, id: id, agent_type: @agent_type
                })
  end

  def delete
    agent = JSONModel(@agent_type).find(params[:id])

    if agent.key?('is_repo_agent')
      flash[:error] = t('errors.cannot_delete_repository_agent')
      redirect_to(controller: :agents, action: :show, id: params[:id])
      return
    end

    begin
      agent.delete
    rescue ConflictException => e
      flash[:error] = t('agent._frontend.messages.delete_conflict', error: t("errors.#{e.conflicts}", default: e.message))
      redirect_to(controller: :agents, action: :show, id: params[:id])
      return
    end

    flash[:success] = t('agent._frontend.messages.deleted', JSONModelI18nWrapper.new(agent: agent))
    redirect_to(controller: :agents, action: :index, deleted_uri: agent.uri)
  end

  def publish
    agent = JSONModel(@agent_type).find(params[:id])

    response = JSONModel::HTTP.post_form("#{agent.uri}/publish")

    if response.code == '200'
      flash[:success] = t('agent._frontend.messages.published', JSONModelI18nWrapper.new(agent: agent).enable_parse_mixed_content!(url_for(:root)))
    else
      flash[:error] = ASUtils.json_parse(response.body)['error'].to_s
    end

    redirect_to request.referer
  end

  def defaults
    defaults = DefaultValues.get params['agent_type']

    @agent = JSONModel(@agent_type).new({ agent_type: @agent_type })._always_valid!

    @agent.update(defaults.form_values) if defaults

    render 'defaults'
  end

  def update_defaults
    DefaultValues.from_hash({
                              'record_type' => @agent_type.to_s,
                              'lock_version' => params['agent'].delete('lock_version'),
                              'defaults' => cleanup_params_for_schema(
                                params['agent'],
                                JSONModel(@agent_type).schema
                              )
                            }).save

    flash[:success] = t('default_values.messages.defaults_updated')
    redirect_to controller: :agents, action: :defaults
  rescue Exception => e
    flash[:error] = e.message
    redirect_to controller: :agents, action: :defaults
  end

  def required
    @agent = JSONModel(@agent_type).new({ agent_type: @agent_type })._always_valid!
    # we are pretending this is an agent form but it's really a RequiredFields form
    @agent.lock_version = @required_fields.lock_version
    render 'required'
  end

  def update_required
    processed_params = cleanup_params_for_schema(
      params['agent'],
      JSONModel(@agent_type).schema
    )
    subrecord_requirements = []

    processed_params.each do |key, defn|
      next unless defn.is_a?(Array) && defn.size == 1
      # we aren't interested in booleans
      defn[0].reject! {|k, v| [false, true].include? (v) }
      subrecord_requirements << {
        property: key,
        record_type: defn[0]['jsonmodel_type'],
        required: (defn[0]['required'] == 'true'),
        required_fields: defn[0].keys.reject { |k| ['jsonmodel_type', 'required'].include?(k) }
      }
    end
    RequiredFields.from_hash({
                               'lock_version' => processed_params['lock_version'],
                               'record_type' => @agent_type.to_s,
                               'subrecord_requirements' => subrecord_requirements}).save
    flash[:success] = t('required_fields.messages.required_fields_updated')
    redirect_to controller: :agents, action: :required
  rescue Exception => e
    flash[:error] = e.message
    redirect_to controller: :agents, action: :required
  end

  def merge
    merge_list = params[:record_uris]
    merge_destination = merge_list[0]
    merge_list.shift
    merge_candidates = merge_list
    merge_destination_type = JSONModel.parse_reference(merge_destination)[:type]
    handle_merge(merge_candidates,
                 merge_destination,
                 'agent',
                 { agent_type: merge_destination_type })
  end

  def merge_selector
    @agent = JSONModel(@agent_type).find(params[:id], find_opts)

    if params[:refs].is_a?(Array)
      flash[:error] = t('errors.merge_too_many_merge_candidates')
      redirect_to({ action: :show, id: params[:id] })
      return
    end

    merge_candidate_details = JSONModel.parse_reference(params[:refs])
    @merge_candidate_type = merge_candidate_details[:type].to_sym
    if @merge_candidate_type != @agent_type
      flash[:error] = t('errors.merge_different_types')
      redirect_to({ action: :show, id: params[:id] })
      return
    end

    @merge_candidate = JSONModel(@merge_candidate_type).find(merge_candidate_details[:id], find_opts)
    if @agent.key?('is_user') || @merge_candidate.key?('is_user')
      flash[:error] = t('errors.merge_denied_for_system_user')
      redirect_to({ action: :show, id: params[:id] })
      return
    end

    relationship_uris = @merge_candidate['related_agents'] ? @merge_candidate['related_agents'].map {|ra| ra['ref']} : []
    if relationship_uris.include?(@agent['uri'])
      flash[:error] = t('errors.merge_denied_relationship')
      redirect_to({ action: :show, id: params[:id] })
      return
    end

    if !user_can?('view_agent_contact_record') && (@agent.agent_contacts.any? || @merge_candidate.agent_contacts.any?)
      flash[:error] = t('errors.merge_restricted_contact_details')
      redirect_to({ action: :show, id: params[:id] })
      return
    end

    render '_merge_selector'
  end

  def merge_detail
    merge_destination_uri = JSONModel(@agent_type).uri_for(params[:id])
    merge_candidate_uri = params['merge_candidate_uri']
    request = JSONModel(:merge_request_detail).new
    request.merge_destination = { 'ref' => merge_destination_uri }
    request.merge_candidates = Array.wrap({ 'ref' => merge_candidate_uri })

    # the backend is expecting to know how the user may have re-ordered subrecords in the merge interface. This information is encoded in the params, but will be stripped out when we clean them up unless we add them as a pseudo schema attribute.
    # add_position_to_agents_merge does exactly this.
    agent_params_with_position = add_position_to_agents_merge_params(params['agent'])
    request.selections = cleanup_params_for_schema(agent_params_with_position, JSONModel(@agent_type).schema)

    uri = "#{JSONModel::HTTP.backend_url}/merge_requests/agent_detail"
    if params['dry_run']
      uri += '?dry_run=true'
      response = JSONModel::HTTP.post_json(URI(uri), request.to_json)
      merge_response = ASUtils.json_parse(response.body)

      @agent = JSONModel(@agent_type).from_hash(merge_response['result'], find_opts)
      render_aspace_partial partial: 'agents/merge_preview', locals: { object: @agent }
    else
      begin
        # For each linked resource or AO, need to remember roles to re-establish with the destination agent.
        candidate_roles = get_merge_candidate_linked_roles(merge_candidate_uri)

        response = JSONModel::HTTP.post_json(URI(uri), request.to_json)

        recreate_linked_record_agent_roles(candidate_roles, merge_destination_uri)

        flash[:success] = t('agent._frontend.messages.merged')
        resolver = Resolver.new(request.merge_destination['ref'])
        redirect_to(resolver.view_uri)
      rescue ValidationException => e
        flash[:error] = e.errors.to_s
        redirect_to({ action: :show, id: params[:id] }.merge(extra_params))
      rescue ConflictException => e
        flash[:error] = t('errors.merge_conflict', message: e.conflicts)
        redirect_to({ action: :show, id: params[:id] }.merge(extra_params))
      rescue RecordNotFound => e
        flash[:error] = t('errors.error_404')
        redirect_to({ action: :show, id: params[:id] }.merge(extra_params))
      end
    end
  end

  private

  def name_type_for_agent_type(agent_type)
    JSONModel(agent_type).type_of('names/items')
  end

  def get_required
    @required_fields = RequiredFields.get @agent_type.to_s
  end

  def assign_types
    return unless params.key? 'agent_type'

    params['agent_type'] = "agent_#{params['agent_type']}" if params['agent_type'] !~ /^agent_/
    @agent_type = :"#{params[:agent_type]}"
    @name_type = name_type_for_agent_type(@agent_type)
  end

  def set_structured_date_type(agent_hash)
    agent_hash['dates_of_existence']&.each do |label|
      if label['structured_date_single']
        label['date_type_structured'] = 'single'
      elsif label['structured_date_range']
        label['date_type_structured'] = 'range'
      else
        label['date_type_structured'] = 'Add or update either a single or ranged date subrecord to set'
      end
    end
    agent_hash['names']&.each do |name|
      next unless name['use_dates']
      name['use_dates'].each do |label|
        if label['structured_date_single']
          label['date_type_structured'] = 'single'
        elsif label['structured_date_range']
          label['date_type_structured'] = 'range'
        else
          label['date_type_structured'] = 'Add or update either a single or ranged date subrecord to set'
        end
      end
    end

    agent_hash['related_agents']&.each do |rel|
      if rel['dates']
        if rel['dates']['structured_date_single']
          rel['dates']['date_type_structured'] = 'single'
        elsif rel['dates']['structured_date_range']
          rel['dates']['date_type_structured'] = 'range'
        else
          rel['dates']['date_type_structured'] = 'Add or update either a single or ranged date subrecord to set'
        end
      end
    end
  end

  def ensure_auth_and_display
    if @agent.names.length == 1
      @agent.names[0]['authorized'] = true
      @agent.names[0]['is_display_name'] = true
    elsif @agent.names.length > 1
      authorized = false
      display = false
      @agent.names.each do |name|
        authorized = true if name['authorized'] == true
        display = true if name['is_display_name'] == true
      end
      @agent.names[0]['authorized'] = true unless authorized
      @agent.names[0]['is_display_name'] = true unless display
    end
  end

  def set_sort_name_default
    @agent.names.each do |name|
      name['sort_name_auto_generate'] = true
    end
  end

  # agent_merge_params looks like this:
  # < ActionController::Parameters {
  # "lock_version" => "3", "agent_record_identifiers" => {
  #  "0" => {
  #    "lock_version" => "0"
  #  }, "1" => {
  #    "lock_version" => "0"
  #  }
  # }, "agent_record_controls" => {
  #  "0" => {
  #    "lock_version" => "0"
  #  }
  # }, "names" => {
  #  "1" => {
  #    "lock_version" => "0", "replace" => "REPLACE"
  #  }, "0" => {
  #    "lock_version" => "0"
  #  }, "2" => {
  #    "lock_version" => "0"
  #  }
  # }
  # This method takes the integer hash keys that represent the original position of the subrecord doing the replacing and adds it as an attribute called "position" under the record type. The result looks like this:
  # "names" => [{
  #   "lock_version" => "0",
  #   "replace" => "REPLACE",
  #   "authorized" => false,
  #   "position" => 1,
  #   "is_display_name" => false,
  #   "sort_name_auto_generate" => false
  # }, {
  #   "lock_version" => "0",
  #   "authorized" => false,
  #   "position" => 0,
  #   "is_display_name" => false,
  #   "sort_name_auto_generate" => false
  # }, {
  #   "lock_version" => "0",
  #   "authorized" => false,
  #   "position" => 2,
  #   "is_display_name" => false,
  #   "sort_name_auto_generate" => false
  # }]
  def add_position_to_agents_merge_params(agent_merge_params)
    agent_merge_params.each do |_param_key, param_value|
      next unless param_value.respond_to?(:each)

      param_value.each do |key, value|
        value['position'] = key if value
      end
    end
  end

  # gathers necessary fields to recreate agent roles in affected resources/AOs
  def get_merge_candidate_linked_roles(merge_candidate_uri)
    filter_term = ["{ \"agent_uris\":\"#{merge_candidate_uri}\" }"]
    search_results = Search.all(session[:repo_id], {'filter_term[]' => filter_term})['results']
    candidate_roles = []
    search_results.each do |result|
      linked_agents = JSON.parse(result['json'])['linked_agents']
      linked_agents.select { |a| a['ref'] == merge_candidate_uri }.each do |linked_agent|
        candidate_roles.append({
          linked_uri: result['uri'],
          title: linked_agent['_resolved']['title'],
          role: linked_agent['role'],
          relator: linked_agent['relator'],
          terms: linked_agent['terms']
        })
      end
    end
    candidate_roles
  end

  def recreate_linked_record_agent_roles(candidate_roles, destination_agent_uri)
    candidate_roles.each do |role|
      linked_type = role[:linked_uri].match(/.*\/(\w+)s\/\d+$/)[1]
      linked_record = JSONModel(linked_type.to_sym).find_by_uri(role[:linked_uri])
      linked_record.linked_agents.append({
        'ref' => destination_agent_uri,
        'role' => role[:role],
        'relator' => role[:relator],
        'terms' => role[:terms]
      })
      linked_record.save
    end
  end

end
