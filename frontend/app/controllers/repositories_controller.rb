class RepositoriesController < ApplicationController

  set_access_control  "view_repository" => [:select, :index, :show, :typeahead],
                      "manage_repository" => [:new, :create, :edit, :update],
                      "transfer_repository" => [:transfer, :run_transfer],
                      "delete_repository" => [:delete],
                      "administer_system" => [:reorder, :run_reorder]


  before_action :refresh_repo_list, :only => [:show, :new]


  def index
    @search_data = Search.global(params_for_backend_search.merge({"facet[]" => []}),
                                 "repositories")
  end

  def reorder
    @repositories = JSONModel(:repository).all.sort_by {|r| r.position }
  end

  def run_reorder
    response = JSONModel::HTTP.post_form("#{JSONModel(:repository).uri_for(params[:id])}/position",
                                         :position => params[:position])
    if response.code == '200'
      flash[:success] = I18n.t("actions.reorder_successful")
    else
      flash[:error] = ASUtils.json_parse(response.body)['error']
    end
    redirect_to(:action => :reorder)
  end

  def new
    @enum = JSONModel(:enumeration).find("/names/archival_record_level")
    @repository = JSONModel(:repository_with_agent).new('repository' => {},
                                                        'agent_representation' => {
                                                          'agent_contacts' => [{}]
                                                        })._always_valid!
  end


  def generate_names(repository_with_agent)
    name = JSONModel(:name_corporate_entity).new
    name['primary_name'] = repository_with_agent['repository']['name'].blank? ? '<generated>' : repository_with_agent['repository']['name']
    name['source'] = 'local'
    name['sort_name'] = name['primary_name']

    repository_with_agent['agent_representation']['names'] = [name]
    if repository_with_agent['agent_representation']['agent_contacts']['0']['name'].blank?
      repository_with_agent['agent_representation']['agent_contacts']['0']['name'] = name['primary_name']
      repository_with_agent['agent_representation']['agent_contacts']['0']['is_representative'] = 1
    end
  end


  def create
    handle_repository_oai_params(params)
    generate_names(params[:repository])
    handle_crud(:instance => :repository,
                :model => JSONModel(:repository_with_agent),
                :on_invalid => ->() {
                  if @exceptions[:errors]["repo_code"]
                    @exceptions[:errors]["repository/repo_code"] = @exceptions[:errors].delete("repo_code")
                  end

                  @enum = JSONModel(:enumeration).find("/names/archival_record_level")

                  return render_aspace_partial :partial => "repositories/new" if inline?
                  return render :action => :new
                },
                :on_valid => ->(id) {
                  MemoryLeak::Resources.refresh(:repository)

                  return render :json => @repository.to_hash if inline?

                  flash[:success] = t("repository._frontend.messages.created")

                  if AppConfig[:use_human_readable_urls] && params["repository"]["repository"] &&
                     (params["repository"]["repository"]["slug"].nil? ||
                      params["repository"]["repository"]["slug"].empty?)  &&
                     !params["repository"]["repository"]["is_slug_auto"]

                    flash[:success] = t("slug.autogen_repo_slug")
                  end

                  return redirect_to :controller => :repositories, :action => :new, :last_repo_id => id if params.has_key?(:plus_one)

                  redirect_to :controller => :repositories, :action => :show, :id => id
                })
  end

  def edit
    @repository = JSONModel(:repository_with_agent).find(params[:id])
    @enum = JSONModel(:enumeration).find("/names/archival_record_level")
  end

  def update
    handle_repository_oai_params(params)
    generate_names(params[:repository])
    handle_crud(:instance => :repository,
                :model => JSONModel(:repository_with_agent),
                :replace => false,
                :obj => JSONModel(:repository_with_agent).find(params[:id]),
                :on_invalid => ->() { return render :action => :edit },
                :on_valid => ->(id) {
                  MemoryLeak::Resources.refresh(:repository)

                  flash[:success] = t("repository._frontend.messages.updated")

                  if AppConfig[:use_human_readable_urls] && params["repository"]["repository"] &&
                     (params["repository"]["repository"]["slug"].nil? ||
                      params["repository"]["repository"]["slug"].empty?)  &&
                     !params["repository"]["repository"]["is_slug_auto"]

                    flash[:warning] = t("slug.autogen_repo_slug")
                  end

                  redirect_to :controller => :repositories, :action => :show, :id => id
                })
  end

  def current_record
    @repository
  end

  def show
    @repository = JSONModel(:repository_with_agent).find(params[:id])
    flash.now[:info] = t("repository._frontend.messages.selected") if @repository.id === session[:repo_id]
    @enum = JSONModel(:enumeration).find("/names/archival_record_level")
  end

  def select
    # Clear top container previous search when switching repositories
    session[:top_container_previous_search] = {}

    selected = @repositories.find {|r| r.id.to_s == params[:id]}
    self.class.session_repo(session, selected.uri, selected.slug)
    set_user_repository_cookie selected.uri

    flash[:success] = t("repository._frontend.messages.changed", repository_repo_code: selected.repo_code)

    redirect_to :root
  end

  def delete
    repository = JSONModel(:repository).find(params[:id])
    begin
      repository.delete
    rescue ConflictException => e
      flash[:error] = t("repository._frontend.messages.cannot_delete_nonempty")
      return redirect_to(:controller => :repositories, :action => :show, :id => params[:id])
    end

    MemoryLeak::Resources.refresh(:repository)

    flash[:success] = t("repository._frontend.messages.deleted")
    redirect_to(:controller => :repositories, :action => :index, :deleted_uri => repository.uri)
  end


  def transfer
    @repository = JSONModel(:repository_with_agent).find(params[:id])
    render :transfer
  end


  def run_transfer
    old_uri = JSONModel(:repository).uri_for(params[:id])
    response = JSONModel::HTTP.post_form(JSONModel(:repository).uri_for(params[:id]) + "/transfer",
                                         "target_repo" => params[:ref])

    if response.code == '200'
      flash[:success] = t("actions.transfer_successful")
      redirect_to(:action => :index)
    else
      @transfer_errors = ASUtils.json_parse(response.body)['error']
      return transfer
    end
  end


  def typeahead
    render :json => Search.global(params_for_backend_search, "repositories")
  end


  private

  def refresh_repo_list
    repo_uri = JSONModel(:repository).uri_for(params[:last_repo_id] || params[:id])
    if @repositories.none? {|repo| repo["uri"] === repo_uri}
      MemoryLeak::Resources.refresh(:repository)
      load_repository_list
    end
  end

    # Because of the form structure, our params for OAI settings are coming into params in separate hashes.
    # This method updates the params hash to pull the data from the right places and serializes them for the DB update.
    # The params hash is a complicated data structure, sorry about the confusing hash references!

    # params["repository"]["repository"] ==> contains the properties of our Repository
    # params["repository"]["repository_oai"] ==> contains the result of the 'OAI enabled' checkbox from the form
    # params["sets"] ==> contains the results of the sets checkboxes

  def handle_repository_oai_params(params)
    repo_params_hash      = params["repository"]["repository"]
    form_oai_enabled_hash = params["repository"]["repository_oai"]
    form_oai_sets_hash    = params["sets"]

    # handle set id checkboxes
    if form_oai_sets_hash
      repo_params_hash["oai_sets_available"] = form_oai_sets_hash.keys.to_json
    else
      repo_params_hash["oai_sets_available"] = "[]"
    end

    # handle oai toggle flag
    if form_oai_enabled_hash
      repo_params_hash["oai_is_disabled"] = form_oai_enabled_hash["oai_is_disabled"]
    else
      repo_params_hash["oai_is_disabled"] = 0
    end
  end
end
