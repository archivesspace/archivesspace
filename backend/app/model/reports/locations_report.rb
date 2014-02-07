#noinspection ALL
class LocationsReport < AbstractReport
  register_report({
                    :uri_suffix => "locations",
                    :description => "Report on repository locations",
                  })

  def initialize(params)
    super
  end

  def headers
    Location.columns
  end

  def processor
    {
      'identifier' => proc {|record| ASUtils.json_parse(record[:identifier] || "[]").compact.join("-")}
    }
  end

  def scope_by_repo_id(dataset)
    # repo scope is applied in the query below
    dataset
  end

# SELECT * FROM "LOCATION" 
# LEFT OUTER JOIN "HOUSED_AT_RLSHP" ON ("HOUSED_AT_RLSHP"."LOCATION_ID" = "LOCATION"."ID") 
# LEFT OUTER JOIN "CONTAINER" ON ("CONTAINER"."ID" = "HOUSED_AT_RLSHP"."CONTAINER_ID") 
# LEFT OUTER JOIN "INSTANCE" ON ("INSTANCE"."ID" = "CONTAINER"."INSTANCE_ID") 
# LEFT OUTER JOIN "RESOURCE" ON ("RESOURCE"."ID" = "INSTANCE"."RESOURCE_ID") 
# LEFT OUTER JOIN "REPOSITORY" ON ("REPOSITORY"."ID" = "RESOURCE"."REPO_ID")
  def query(db)
    dataset = db[:location].
      left_outer_join(:housed_at_rlshp, :location_id => :location__id).
      left_outer_join(:container, :id => :housed_at_rlshp__container_id).
      left_outer_join(:instance, :id => :container__instance_id).
      left_outer_join(:resource, :id => :instance__resource_id).
      left_outer_join(:repository, :id => :resource__repo_id)

    dataset = dataset.where(Sequel.qualify(:repository, :id) => @repo_id) if @repo_id

  end

end
