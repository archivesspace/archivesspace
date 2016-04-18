class SpaceCalculatorController < ApplicationController

  set_access_control  "view_repository" => [:show, :calculate]

  def show
    @container_profile_ref = params[:container_profile_ref]

    unless @container_profile_ref.blank?
      @container_profile = JSONModel(:container_profile).find_by_uri(@container_profile_ref)
    end

    @buildings = JSONModel::HTTP.get_json("/space_calculator/buildings")

    @selectable = params[:selectable] == "true"

    render_aspace_partial :partial => "space_calculator/form"
  end

  def calculate
    if params[:container_profile]
      @container_profile_ref = params[:container_profile][:ref]
    end

    if params[:location]
      # by location(s)
      @location_refs = ASUtils.wrap(params[:location]).map{|loc| loc[:ref]}.flatten.compact

      if @container_profile_ref && @location_refs
        @results = JSONModel::HTTP.get_json("/space_calculator/by_location", {
          'container_profile_uri' => @container_profile_ref,
          'location_uris[]' => @location_refs
        })
      end
    elsif params[:building]
      # by building
      building = params[:building]
      floor = params[:floor].blank? ? nil : params[:floor]
      room = params[:room].blank? ? nil : params[:room]
      area = params[:area].blank? ? nil : params[:area]

      @by_building = true

      if @container_profile_ref
        @results = JSONModel::HTTP.get_json("/space_calculator/by_building", {
          'container_profile_uri' => @container_profile_ref,
          'building' => building,
          'floor' => floor,
          'room' => room,
          'area' => area,
        })
      end
    end

    @selectable = params[:selectable] == "true"

    render_aspace_partial :partial =>  "space_calculator/results"
  end



end

