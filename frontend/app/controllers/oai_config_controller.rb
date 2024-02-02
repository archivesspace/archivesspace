class OaiConfigController < ApplicationController

  set_access_control "manage_repository" => [:edit, :update]

  def edit
    @oai_config = JSONModel(:oai_config).all.first
    @repositories = JSONModel(:repository).all
  end

  def update
    handle_oai_config_params(params)
    @oai_config = JSONModel(:oai_config).all.first

    handle_crud(:instance => :oai_config,
                :model => JSONModel(:oai_config),
                :replace => false,
                :obj => @oai_config,
                :on_invalid => ->() { return render :action => :edit },
                :on_valid => ->(id) {
                  flash[:success] = t("oai_config._frontend.action.updated")
                  redirect_to :controller => :oai_config, :action => :edit
                })
  end

  def current_record
    @oai_config
  end

  private


    # Because of the form structure, our params for OAI settings are coming into params in separate hashes.
    # This method updates the params hash to pull the data from the right places and serializes them for the DB update.
    # The params hash is a complicated data structure, sorry about the confusing hash references!

    # params["repo_set_codes"] ==> contains the results of the repository OAI set of checkboxes
    # params["oai_config"] ==> contains the rest of the OAI config hash
  def handle_oai_config_params(params)
    repo_set_codes_hash = params["repo_set_codes"]
    oai_config_hash = params["oai_config"]

    if repo_set_codes_hash
      oai_config_hash['repo_set_codes'] = params["repo_set_codes"].keys.to_json
    else
      oai_config_hash['repo_set_codes'] = "[]"
    end

    # The sponsor set name param looks like:
    # "Sponsor 1,Sponsor 2"
    # Turn into a serialized array for DB
    if oai_config_hash['sponsor_set_names']
      oai_config_hash['sponsor_set_names'] = oai_config_hash['sponsor_set_names'].split("|").to_json
    else
      oai_config_hash['sponsor_set_names'] = "[]"
    end
  end
end
