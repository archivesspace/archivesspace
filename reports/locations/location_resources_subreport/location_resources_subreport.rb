class LocationResourcesSubreport < AbstractReport

  def template
    "location_resources_subreport.erb"
  end

  def query
    resource_locations = db[:location]
                           .inner_join(:top_container_housed_at_rlshp, :top_container_housed_at_rlshp__id => :location__id)
                           .inner_join(:top_container, :top_container__id => :top_container_housed_at_rlshp__top_container_id)
                           .inner_join(:top_container_link_rlshp, :top_container_link_rlshp__top_container_id => :top_container__id)
                           .inner_join(:sub_container, :sub_container__id => :top_container_link_rlshp__sub_container_id)
                           .inner_join(:instance, :instance__id => :sub_container__instance_id)
                           .inner_join(:resource, :resource__id => :instance__resource_id)
                           .filter(:location__id => @params.fetch(:location_id))
                           .select(Sequel.as(:resource__id, :id),
                                   Sequel.as(:resource__identifier, :identifier),
                                   Sequel.as(:resource__title, :title))

    archival_object_locations = db[:location]
                                  .inner_join(:top_container_housed_at_rlshp, :top_container_housed_at_rlshp__id => :location__id)
                                  .inner_join(:top_container, :top_container__id => :top_container_housed_at_rlshp__top_container_id)
                                  .inner_join(:top_container_link_rlshp, :top_container_link_rlshp__top_container_id => :top_container__id)
                                  .inner_join(:sub_container, :sub_container__id => :top_container_link_rlshp__sub_container_id)
                                  .inner_join(:instance, :instance__id => :sub_container__instance_id)
                                  .inner_join(:archival_object, :archival_object__id => :instance__archival_object_id)
                                  .inner_join(:resource, :resource__id => :archival_object__root_record_id)
                                  .filter(:location__id => @params.fetch(:location_id))
                                  .select(Sequel.as(:resource__id, :id),
                                          Sequel.as(:resource__identifier, :identifier),
                                          Sequel.as(:resource__title, :title))


    resource_locations
      .union(archival_object_locations)
  end

end
