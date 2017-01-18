class ResourceInstancesSubreport < AbstractReport

  def template
    'resource_instances_subreport.erb'
  end

  # FIXME might be nice to group the containers by their top container?
  # They are currently listed one per row (see hornstein)
  def query
    resource_id = @params.fetch(:resourceId)
    all_children_ids = db[:archival_object]
                        .filter(:root_record_id => resource_id)
                        .select(:id)
    db[:instance]
      .inner_join(:sub_container, :instance_id => :instance__id)
      .inner_join(:top_container_link_rlshp, :sub_container_id => :sub_container__id)
      .inner_join(:top_container, :id => :top_container_link_rlshp__top_container_id)
      .left_outer_join(:top_container_profile_rlshp, :top_container_id => :top_container__id)
      .left_outer_join(:container_profile, :id => :top_container_profile_rlshp__container_profile_id)
      .filter {
        Sequel.|({:instance__resource_id => resource_id},
                 :instance__archival_object_id => all_children_ids)
      }
      .select(Sequel.as(Sequel.lit("CONCAT(COALESCE(container_profile.name, ''), ' ', top_container.indicator)"), :container),
              Sequel.as(Sequel.lit("GetEnumValueUF(sub_container.type_2_id)"), :container2Type),
              Sequel.as(:sub_container__indicator_2, :container2Indicator),
              Sequel.as(Sequel.lit("GetEnumValueUF(sub_container.type_3_id)"), :container3Type),
              Sequel.as(:sub_container__indicator_3, :container3Indicator))
      .distinct
  end

end
