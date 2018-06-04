class LocationAccessionsSubreport < AbstractSubreport
  def initialize(parent_report, location_id)
    super(parent_report)
    @location_id = location_id
  end

  def query
    db[:location]
      .inner_join(:top_container_housed_at_rlshp, top_container_housed_at_rlshp__location_id: :location__id)
      .inner_join(:top_container, top_container__id: :top_container_housed_at_rlshp__top_container_id)
      .inner_join(:top_container_link_rlshp, top_container_link_rlshp__top_container_id: :top_container__id)
      .inner_join(:sub_container, sub_container__id: :top_container_link_rlshp__sub_container_id)
      .inner_join(:instance, instance__id: :sub_container__instance_id)
      .inner_join(:accession, accession__id: :instance__accession_id)
      .filter(location__id: @location_id)
      .filter(accession__repo_id: repo_id)
      .select(Sequel.as(:accession__identifier, :identifier),
              Sequel.as(:accession__title, :title))
  end

  def fix_row(row)
    ReportUtils.fix_identifier_format(row)
  end
end
