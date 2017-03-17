class AccessionLocationsSubreport < AbstractReport

  def template
    "accession_locations_subreport.erb"
  end

  def query
    db[:instance]
      .inner_join(:sub_container, :instance_id => :instance__id)
      .inner_join(:top_container_link_rlshp, :sub_container_id => :sub_container__id)
      .inner_join(:top_container, :id => :top_container_link_rlshp__top_container_id)
      .left_outer_join(:top_container_profile_rlshp, :top_container_id => :top_container__id)
      .left_outer_join(:container_profile, :id => :top_container_profile_rlshp__container_profile_id)
      .inner_join(:top_container_housed_at_rlshp, :top_container_id => :top_container__id)
      .inner_join(:location, :id => :top_container_housed_at_rlshp__location_id)
      .group_by(:location__id)
      .filter(:instance__accession_id => @params.fetch(:accessionId))
      .select(Sequel.as(:location__title, :location),
              Sequel.as(Sequel.lit("GROUP_CONCAT(CONCAT(COALESCE(container_profile.name, ''), ' ', top_container.indicator) SEPARATOR ', ')"), :container))
  end

end
