class OaiConfigController < ApplicationController

  set_access_control  "manage_repository" => [:edit, :update]

  def edit
    @oai_config = JSONModel(:oai_config).all.first
    @repositories = JSONModel(:repository).all
  end

  def update
    @oai_config = JSONModel(:oai_config).all.first

    handle_crud(:instance => :oai_config,
                :model => JSONModel(:oai_config),
                :replace => false,
                :obj => @oai_config,
                :on_invalid => ->(){ return render :action => :edit },
                :on_valid => ->(id){
                  flash[:success] = I18n.t("oai_config._frontend.action.updated")
                  redirect_to :controller => :oai_config, :action => :edit
                })
  end
end

