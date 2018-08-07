class OaiConfigController < ApplicationController

  set_access_control  "manage_repository" => [:edit, :update]

  def edit
    @oai_config = JSONModel(:oai_config).all.first
  end

  def update
    @oai_config = JSONModel(:oai_config).all.first
    puts "++++++++++++++++++++++++++++"
    puts "IN UPDATE"
    puts "oai_config: " + @oai_config.inspect
    puts "params: " + params.inspect
    begin

    handle_crud(:instance => :oai_config,
                :model => JSONModel(:oai_config),
                :replace => false,
                :obj => @oai_config,
                :on_invalid => ->(){ return render :action => :edit },
                :on_valid => ->(id){
                  flash[:success] = I18n.t("oai_config._frontend.action.updated")
                  redirect_to :controller => :oai_config, :action => :edit
                })
  rescue => e
    puts e.message
    puts e.backtrace
  end
  end
end

