class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/extent_calculator')
  .description("Calculate the extent of an archival object tree")
  .params(["record_uri", String, "The uri of the object"],
          ["unit", String, "The unit of measurement to use", :optional => true])
  .permissions([])
  .returns([200, "Calculation results"]) \
  do
    parsed = JSONModel.parse_reference(params[:record_uri])
    RequestContext.open(:repo_id => JSONModel(:repository).id_for(parsed[:repository])) do
      obj = Kernel.const_get(parsed[:type].to_s.camelize)[parsed[:id]]
      ext_cal = ExtentCalculator.new(obj)
      ext_cal.units = params[:unit].intern if params[:unit]
      json_response(ext_cal.to_hash)
    end
  end

end
