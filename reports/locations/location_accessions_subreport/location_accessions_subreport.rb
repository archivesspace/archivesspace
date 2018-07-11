class LocationAccessionsSubreport < AbstractReport

  def template
    "location_accessions_subreport.erb"
  end

  def query
    db[:location]
      .inner_join(:top_container_housed_at_rlshp, :top_container_housed_at_rlshp__location_id => :location__id)
      .inner_join(:top_container, :top_container__id => :top_container_housed_at_rlshp__top_container_id)
      .inner_join(:top_container_link_rlshp, :top_container_link_rlshp__top_container_id => :top_container__id)
      .inner_join(:sub_container, :sub_container__id => :top_container_link_rlshp__sub_container_id)
      .inner_join(:instance, :instance__id => :sub_container__instance_id)
      .inner_join(:accession, :accession__id => :instance__accession_id)
      .filter(:location__id => @params.fetch(:location_id))
      .select(Sequel.as(:accession__id, :id),
              Sequel.as(:accession__identifier, :identifier),
              Sequel.as(:accession__title, :title))
  end

end
