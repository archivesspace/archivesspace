class AgentsController < ApplicationController

  set_access_control  "view_repository" => [:index, :show],
                      "update_agent_record" => [:new, :edit, :create, :update, :merge, :merge_selector, :merge_detail, :merge_preview],
                      "delete_agent_record" => [:delete],
                      "manage_repository" => [:defaults, :update_defaults, :required, :update_required]


  before_action :assign_types

  include ExportHelper

  def index
    respond_to do |format|
      format.html {
        @search_data = Search.for_type(session[:repo_id], "agent", params_for_backend_search.merge({"facet[]" => SearchResultData.AGENT_FACETS}))
      }
      format.csv {
        search_params = params_for_backend_search.merge({"facet[]" => SearchResultData.AGENT_FACETS})
        search_params["type[]"] = "agent"
        uri = "/repositories/#{session[:repo_id]}/search"
        csv_response( uri, search_params )
      }
    end
  end

  def show
    @agent = JSONModel(@agent_type).find(params[:id], find_opts)
  end

  def new
    @agent = JSONModel(@agent_type).new({:agent_type => @agent_type})._always_valid!
    if user_prefs['default_values']
      defaults = DefaultValues.get @agent_type.to_s
      @agent.update(defaults.values) if defaults
    end

    required = RequiredFields.get @agent_type.to_s
    begin
      @agent.update_concat(required.values) if required
    rescue Exception => e
      flash[:error] = e.message
      redirect_to :controller => :agents, :action => :required
    end

    if @agent.names.empty?
      @agent.names = [@name_type.new({:authorized => true, :is_display_name => true})._always_valid!]
    end

    ensure_auth_and_display()

    set_sort_name_default()

    render_aspace_partial :partial => "agents/new" if inline?
  end

  def edit
    @agent = JSONModel(@agent_type).find(params[:id], find_opts)
  end

  def create
    required = RequiredFields.get @agent_type.to_s
    if required
      required_values = required.values
    else
      required_values = nil
    end
    handle_crud(:instance => :agent,
                :model => JSONModel(@agent_type),
                :required => required_values,
                :find_opts => find_opts,
                :on_invalid => ->(){
                  required = RequiredFields.get @agent_type.to_s
                  @agent.update_concat(required.values) if required
                  ensure_auth_and_display()
                  return render_aspace_partial :partial => "agents/new" if inline?
                  return render :action => :new
                },
                :on_valid => ->(id){
                  flash[:success] = I18n.t("agent._frontend.messages.created")

                  if @agent["is_slug_auto"] == false &&
                     @agent["slug"] == nil &&
                     params["agent"] &&
                     params["agent"]["is_slug_auto"] == "1"
                    flash[:warning] = I18n.t("slug.autogen_disabled")
                  end

                  return render :json => @agent.to_hash if inline?
                  return redirect_to({:controller => :agents, :action => :new, :agent_type => @agent_type}) if params.has_key?(:plus_one)
                  redirect_to({:controller => :agents, :action => :edit, :id => id, :agent_type => @agent_type})
                })
  end

  def update
    handle_crud(:instance => :agent,
                :model => JSONModel(@agent_type),
                :obj => JSONModel(@agent_type).find(params[:id], find_opts),
                :on_invalid => ->(){
                  if @agent.names.empty?
                    @agent.names = [@name_type.new._always_valid!]
                  end

                  return render :action => :edit
                },
                :on_valid => ->(id){
                  flash[:success] = I18n.t("agent._frontend.messages.updated")
                  if @agent["is_slug_auto"] == false &&
                     @agent["slug"] == nil &&
                     params["agent"] &&
                     params["agent"]["is_slug_auto"] == "1"
                    flash[:warning] = I18n.t("slug.autogen_disabled")
                  end

                  redirect_to :controller => :agents, :action => :edit, :id => id, :agent_type => @agent_type
                })
  end


  def delete
    agent = JSONModel(@agent_type).find(params[:id])

    begin
      agent.delete
    rescue ConflictException => e
      flash[:error] = I18n.t("agent._frontend.messages.delete_conflict", :error => I18n.t("errors.#{e.conflicts}", :default => e.message))
      redirect_to(:controller => :agents, :action => :show, :id => params[:id])
      return
    end

    flash[:success] = I18n.t("agent._frontend.messages.deleted", JSONModelI18nWrapper.new(:agent => agent))
    redirect_to(:controller => :agents, :action => :index, :deleted_uri => agent.uri)
  end

  def defaults
    defaults = DefaultValues.get params['agent_type']

    @agent = JSONModel(@agent_type).new({:agent_type => @agent_type})._always_valid!

    @agent.update(defaults.form_values) if defaults

    render 'defaults'
  end

  def update_defaults

    begin

      DefaultValues.from_hash({
                                "record_type" => @agent_type.to_s,
                                "lock_version" => params['agent'].delete('lock_version'),
                                "defaults" => cleanup_params_for_schema(
                                                                        params['agent'],
                                                                        JSONModel(@agent_type).schema)
                              }).save

      flash[:success] = I18n.t("default_values.messages.defaults_updated")
      redirect_to :controller => :agents, :action => :defaults
    rescue Exception => e
      flash[:error] = e.message
      redirect_to :controller => :agents, :action => :defaults
    end
  end

  def required
    required = RequiredFields.get params['agent_type']

    @agent = JSONModel(@agent_type).new({:agent_type => @agent_type})._always_valid!

    @agent.update(required.form_values) if required

    render 'required'

  end

  def update_required
    begin

      RequiredFields.from_hash({
                                "record_type" => @agent_type.to_s,
                                "lock_version" => params['agent'].delete('lock_version'),
                                "required" => cleanup_params_for_schema(
                                                                        params['agent'],
                                                                        JSONModel(@agent_type).schema)
                              }).save

      flash[:success] = I18n.t("required_fields.messages.required_fields_updated")
      redirect_to :controller => :agents, :action => :required
    rescue Exception => e
      flash[:error] = e.message
      redirect_to :controller => :agents, :action => :required
    end
  end


  def merge
    merge_list = params[:record_uris]
    target = merge_list[0]
    merge_list.shift
    victims = merge_list
    target_type = JSONModel.parse_reference(target)[:type]
    handle_merge( victims,
                  target,
                  'agent',
                  {:agent_type => target_type})
  end
  def merge_selector
    @agent = JSONModel(@agent_type).find(params[:id], find_opts)
    if params[:refs].is_a?(Array)
      flash[:error] = I18n.t("errors.merge_too_many_victims")
      redirect_to({:action => :show, :id => params[:id]})
    elsif params[:refs].is_a?(String)
      victim_details = JSONModel.parse_reference(params[:refs])
      @victim_type = victim_details[:type].to_sym
      if @victim_type != @agent_type
        flash[:error] = I18n.t("errors.merge_different_types")
        redirect_to({:action => :show, :id => params[:id]})
      else
        @victim = JSONModel(@victim_type).find(victim_details[:id], find_opts)
        if @agent.has_key?("is_user") || @victim.has_key?("is_user")
          flash[:error] = "One or more agents is a system user"
          redirect_to({:action => :show, :id => params[:id]})
        else
          render '_merge_selector'
        end
      end
    end
  end
  def merge_detail
    request = JSONModel(:merge_request_detail).new
    request.target = {'ref' => JSONModel(@agent_type).uri_for(params[:id])}
    request.victims = Array.wrap({ 'ref' => params['victim_uri'] })
    request.selections = cleanup_params_for_schema(params['agent'], JSONModel(@agent_type).schema)
    uri = "#{JSONModel::HTTP.backend_url}/merge_requests/agent_detail"
    if params["dry_run"]
      uri += "?dry_run=true"
      response = JSONModel::HTTP.post_json(URI(uri), request.to_json)
      merge_response = ASUtils.json_parse(response.body)
      @agent = JSONModel(@agent_type).from_hash(merge_response, find_opts)
      render_aspace_partial :partial => "agents/merge_preview", :locals => {:object => @agent}
    else
      begin
        response = JSONModel::HTTP.post_json(URI(uri), request.to_json)
        if response.message === "OK"
          flash[:success] = I18n.t("agent._frontend.messages.merged")
          resolver = Resolver.new(request.target["ref"])
          redirect_to(resolver.view_uri)
        end
      rescue ValidationException => e
        flash[:error] = e.errors.to_s
        redirect_to({:action => :show, :id => params[:id]}.merge(extra_params))
      rescue ConflictException => e
        flash[:error] = I18n.t("errors.merge_conflict", :message => e.conflicts)
        redirect_to({:action => :show, :id => params[:id]}.merge(extra_params))
      rescue RecordNotFound => e
        flash[:error] = I18n.t("errors.error_404")
        redirect_to({:action => :show, :id => params[:id]}.merge(extra_params))
      end
    end
  end


  private

    def name_type_for_agent_type(agent_type)
      JSONModel(agent_type).type_of("names/items")
    end

    def assign_types
      return if not params.has_key? 'agent_type'

      @agent_type = :"#{params[:agent_type]}"
      @name_type = name_type_for_agent_type(@agent_type)
    end

    def ensure_auth_and_display
      if @agent.names.length == 1
        @agent.names[0]["authorized"] = true
        @agent.names[0]["is_display_name"] = true
      elsif @agent.names.length > 1
        authorized = false
        display = false
        @agent.names.each do |name|
          if name["authorized"] == true
            authorized = true
          end
          if name["is_display_name"] == true
            display = true
          end
        end
        if !authorized
          @agent.names[0]["authorized"] = true
        end
        if !display
          @agent.names[0]["is_display_name"] = true
        end
      end
    end

    def set_sort_name_default
      @agent.names.each do |name|
        name["sort_name_auto_generate"] = true
      end
    end

end
