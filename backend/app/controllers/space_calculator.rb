class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/space_calculator/by_location')
    .description("Calculate how many containers will fit in a list of locations")
    .params(["container_profile_uri", String, "The uri of the container profile"],
            ["location_uris", [String], "A list of location uris to calculate space for"])
    .permissions([])
    .returns([200, "Calculation results"]) \
  do
    cp_ref = JSONModel.parse_reference(params[:container_profile_uri])
    cp = Kernel.const_get(cp_ref[:type].to_s.camelize)[cp_ref[:id]]
    locs = Array(params[:location_uris]).map do |uri|
      loc_ref = JSONModel.parse_reference(uri)
      Kernel.const_get(loc_ref[:type].to_s.camelize)[loc_ref[:id]]
    end

    space_calculator = SpaceCalculator.new(cp, locs)

    json_response(resolve_references_for_space_calculator(space_calculator))
  end


  Endpoint.get('/space_calculator/by_building')
    .description("Calculate how many containers will fit in locations for a given building")
    .params(["container_profile_uri", String, "The uri of the container profile"],
            ["building", String, "The building to check for space in"],
            ["floor", String, "The floor to check for space in", :optional => true],
            ["room", String, "The room to check for space in", :optional => true],
            ["area", String, "The area to check for space in", :optional => true])
    .permissions([])
    .returns([200, "Calculation results"]) \
  do
    cp_ref = JSONModel.parse_reference(params[:container_profile_uri])
    cp = Kernel.const_get(cp_ref[:type].to_s.camelize)[cp_ref[:id]]

    locs = Location.for_building(params[:building],
                                 params[:floor],
                                 params[:room],
                                 params[:area])

    space_calculator = SpaceCalculator.new(cp, locs)

    json_response(resolve_references_for_space_calculator(space_calculator))
  end


  Endpoint.get('/space_calculator/buildings')
    .description("Get a Location by ID")
    .permissions([])
    .returns([200, "Location building data as JSON"]) \
  do
    json = Location.building_data
    json_response(json)
  end


  def resolve_references_for_space_calculator(space_calculator)
    refs_to_resolve = ['locations_with_space',
                       'locations_with_space::location_profile',
                       'locations_without_space',
                       'locations_without_space::location_profile',
                       'uncalculatable_locations',
                       'uncalculatable_locations::location_profile']

    resolve_references(space_calculator.to_hash, refs_to_resolve)
  end
end
