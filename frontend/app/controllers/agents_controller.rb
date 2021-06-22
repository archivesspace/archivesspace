# frozen_string_literal: true

class AgentsController < ApplicationController
  set_access_control  'view_repository' => [:index, :show],
                      'update_agent_record' => [:new, :edit, :create, :update, :publish, :merge, :merge_selector, :merge_detail, :merge_preview],
                      'delete_agent_record' => [:delete],
                      'manage_repository' => [:defaults, :update_defaults, :required, :update_required]

  before_action :assign_types
  before_action :set_structured_date_type, only: [:create, :update]
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
        csv_response(uri, Search.build_filters(search_params), "#{I18n.t('agent._plural').downcase}.")
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

    begin
      if @required.class == RequiredFields
        @agent.update_concat(@required.values)
      end
    rescue Exception => e
      flash[:error] = e.message
      redirect_to controller: :agents, action: :required
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
    required_values = (@required.values if @required.class == RequiredFields)
    handle_crud(instance: :agent,
                model: JSONModel(@agent_type),
                required: required_values,
                find_opts: find_opts,
                on_invalid: lambda {
                  @required = RequiredFields.get @agent_type.to_s
                  @required = {} if @required.nil?
                  if @required.class == RequiredFields
                    @agent.update_concat(@required.values)
                  end
                  ensure_auth_and_display
                  return render_aspace_partial partial: 'agents/new' if inline?

                  return render action: :new
                },
                on_valid: lambda  { |id|
                  flash[:success] = I18n.t('agent._frontend.messages.created')

                  if @agent['is_slug_auto'] == false &&
                     @agent['slug'].nil? &&
                     params['agent'] &&
                     params['agent']['is_slug_auto'] == '1'

                    flash[:warning] = I18n.t('slug.autogen_disabled')
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
                on_invalid: lambda {
                  if @agent.names.empty?
                    @agent.names = [@name_type.new._always_valid!]
                  end

                  return render action: :edit
                },
                on_valid: lambda  { |id|
                  flash[:success] = I18n.t('agent._frontend.messages.updated')
                  if @agent['is_slug_auto'] == false &&
                     @agent['slug'].nil? &&
                     params['agent'] &&
                     params['agent']['is_slug_auto'] == '1'

                    flash[:warning] = I18n.t('slug.autogen_disabled')
                  end

                  redirect_to controller: :agents, action: :edit, id: id, agent_type: @agent_type
                })
  end

  def delete
    agent = JSONModel(@agent_type).find(params[:id])

    if agent.key?('is_repo_agent')
      flash[:error] = I18n.t('errors.cannot_delete_repository_agent')
      redirect_to(controller: :agents, action: :show, id: params[:id])
      return
    end

    begin
      agent.delete
    rescue ConflictException => e
      flash[:error] = I18n.t('agent._frontend.messages.delete_conflict', error: I18n.t("errors.#{e.conflicts}", default: e.message))
      redirect_to(controller: :agents, action: :show, id: params[:id])
      return
    end

    flash[:success] = I18n.t('agent._frontend.messages.deleted', JSONModelI18nWrapper.new(agent: agent))
    redirect_to(controller: :agents, action: :index, deleted_uri: agent.uri)
  end

  def publish
    agent = JSONModel(@agent_type).find(params[:id])

    response = JSONModel::HTTP.post_form("#{agent.uri}/publish")

    if response.code == '200'
      flash[:success] = I18n.t('agent._frontend.messages.published', JSONModelI18nWrapper.new(agent: agent).enable_parse_mixed_content!(url_for(:root)))
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

    flash[:success] = I18n.t('default_values.messages.defaults_updated')
    redirect_to controller: :agents, action: :defaults
  rescue Exception => e
    flash[:error] = e.message
    redirect_to controller: :agents, action: :defaults
  end

  def required
    @agent = JSONModel(@agent_type).new({ agent_type: @agent_type })._always_valid!

    @agent.update(@required.form_values) if @required.class == RequiredFields

    render 'required'
  end

  def update_required
    RequiredFields.from_hash({
                               'record_type' => @agent_type.to_s,
                               'lock_version' => params['agent'].delete('lock_version'),
                               'required' => cleanup_params_for_schema(
                                 params['agent'],
                                 JSONModel(@agent_type).schema
                               )
                             }).save

    flash[:success] = I18n.t('required_fields.messages.required_fields_updated')
    redirect_to controller: :agents, action: :required
  rescue Exception => e
    flash[:error] = e.message
    redirect_to controller: :agents, action: :required
  end

  def merge
    merge_list = params[:record_uris]
    target = merge_list[0]
    merge_list.shift
    victims = merge_list
    target_type = JSONModel.parse_reference(target)[:type]
    handle_merge(victims,
                 target,
                 'agent',
                 { agent_type: target_type })
  end

  def merge_selector
    @agent = JSONModel(@agent_type).find(params[:id], find_opts)

    if params[:refs].is_a?(Array)
      flash[:error] = I18n.t('errors.merge_too_many_victims')
      redirect_to({ action: :show, id: params[:id] })
      return
    end

    victim_details = JSONModel.parse_reference(params[:refs])
    @victim_type = victim_details[:type].to_sym
    if @victim_type != @agent_type
      flash[:error] = I18n.t('errors.merge_different_types')
      redirect_to({ action: :show, id: params[:id] })
      return
    end

    @victim = JSONModel(@victim_type).find(victim_details[:id], find_opts)
    if @agent.key?('is_user') || @victim.key?('is_user')
      flash[:error] = I18n.t('errors.merge_denied_for_system_user')
      redirect_to({ action: :show, id: params[:id] })
      return
    end

    relationship_uris = @victim['related_agents'].map {|ra| ra['ref']}
    if relationship_uris.include?(@agent['uri'])
      flash[:error] = I18n.t('errors.merge_denied_relationship')
      redirect_to({ action: :show, id: params[:id] })
      return
    end

    if !user_can?('view_agent_contact_record') && (@agent.agent_contacts.any? || @victim.agent_contacts.any?)
      flash[:error] = I18n.t('errors.merge_restricted_contact_details')
      redirect_to({ action: :show, id: params[:id] })
      return
    end

    render '_merge_selector'
  end

  def merge_detail
    request = JSONModel(:merge_request_detail).new
    request.target = { 'ref' => JSONModel(@agent_type).uri_for(params[:id]) }
    request.victims = Array.wrap({ 'ref' => params['victim_uri'] })

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
        response = JSONModel::HTTP.post_json(URI(uri), request.to_json)

        flash[:success] = I18n.t('agent._frontend.messages.merged')
        resolver = Resolver.new(request.target['ref'])
        redirect_to(resolver.view_uri)
      rescue ValidationException => e
        flash[:error] = e.errors.to_s
        redirect_to({ action: :show, id: params[:id] }.merge(extra_params))
      rescue ConflictException => e
        flash[:error] = I18n.t('errors.merge_conflict', message: e.conflicts)
        redirect_to({ action: :show, id: params[:id] }.merge(extra_params))
      rescue RecordNotFound => e
        flash[:error] = I18n.t('errors.error_404')
        redirect_to({ action: :show, id: params[:id] }.merge(extra_params))
      end
    end
  end

  private

  def name_type_for_agent_type(agent_type)
    JSONModel(agent_type).type_of('names/items')
  end

  def get_required
    @required = RequiredFields.get @agent_type.to_s
    @required = {} if @required.nil?
  end

  def assign_types
    return unless params.key? 'agent_type'

    @agent_type = :"#{params[:agent_type]}"
    @name_type = name_type_for_agent_type(@agent_type)
  end

  def set_structured_date_type
    params['agent']['dates_of_existence']&.each do |_key, label|
      if label['structured_date_single']
        label['date_type_structured'] = 'single'
      elsif label['structured_date_range']
        label['date_type_structured'] = 'range'
      else
        label['date_type_structured'] = 'Add or update either a single or ranged date subrecord to set'
      end
    end

    params['agent']['names']&.each do |_key, name|
      next unless name['use_dates']

      name['use_dates'].each do |_key, label|
        if label['structured_date_single']
          label['date_type_structured'] = 'single'
        elsif label['structured_date_range']
          label['date_type_structured'] = 'range'
        else
          label['date_type_structured'] = 'Add or update either a single or ranged date subrecord to set'
        end
      end
    end

    params['agent']['related_agents']&.each do |_key, rel|
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
end
