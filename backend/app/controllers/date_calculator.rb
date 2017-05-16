class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/date_calculator')
  .description("Calculate the dates of an archival object tree")
  .params(["record_uri", String, "The uri of the object"],
          ["label", String, "The date label to filter on", :optional => true])
  .permissions([])
  .returns([200, "Calculation results"]) \
  do
    parsed = JSONModel.parse_reference(params[:record_uri])

    RequestContext.open(:repo_id => JSONModel(:repository).id_for(parsed[:repository])) do
      raise AccessDeniedException.new unless current_user.can?(:view_repository)

      obj = Kernel.const_get(parsed[:type].to_s.camelize)[parsed[:id]]
      date_cal = DateCalculator.new(obj, params[:label])
      json_response(date_cal.to_hash)
    end
  end

end
