class OaiConfigController < ApplicationController

  set_access_control  "manage_repository" => [:edit, :update]

  def edit
    @oai_config = JSONModel(:oai_config).all.first

    puts "++++++++++++++++++++++++++++"
    puts "oai config: " + @oai_config.inspect
  end

  def update
  #handle_repository_oai_params(params)
  #generate_names(params[:repository])
  #handle_crud(:instance => :repository,
              #:model => JSONModel(:repository_with_agent),
              #:replace => false,
              #:obj => JSONModel(:repository_with_agent).find(params[:id]),
              #:on_invalid => ->(){ return render :action => :edit },
              #:on_valid => ->(id){
                #MemoryLeak::Resources.refresh(:repository)
#
                #flash[:success] = I18n.t("repository._frontend.messages.updated", JSONModelI18nWrapper.new(:repository => @repository))
                #redirect_to :controller => :repositories, :action => :show, :id => id
              #})
  end

end
