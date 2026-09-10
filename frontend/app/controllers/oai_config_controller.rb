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

  def handle_oai_config_params(params)
    oai_config_hash = params["oai_config"]

    return if oai_config_hash.nil?

    oai_config_hash["oai_repository_sets"] ||= []
    oai_config_hash["oai_sponsor_sets"] ||= []

    each_subrecord(oai_config_hash["oai_sponsor_sets"]) do |sponsor_set|
      names = sponsor_set["sponsor_names"]
      next unless names.is_a?(String)

      sponsor_set["sponsor_names"] = names.split("|").map(&:strip).reject(&:empty?)
    end
  end

  # Indexed subrecord params arrive keyed by position, not as an array.
  def each_subrecord(subrecords, &block)
    (subrecords.respond_to?(:values) ? subrecords.values : subrecords).each(&block)
  end
end
