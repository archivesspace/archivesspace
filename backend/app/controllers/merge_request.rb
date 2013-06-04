class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/merge_requests/subject')
    .description("Carry out a merge request")
    .params(["merge_request", JSONModel(:merge_request), "The Request", :body => true])
    .permissions([:update_subject_record])
    .returns([200, :updated]) \
  do
    request = params[:merge_request]

    target = JSONModel.parse_reference(request.target['ref'])
    victims = request.victims.map {|victim| JSONModel.parse_reference(victim['ref']) }

    if (victims.map {|r| r[:type]} + [target[:type]]).any? {|type| type != 'subject'}
      raise BadParamsException.new(:merge_request => ["Subject merge request can only merge subject records"])
    end

    Subject.get_or_die(target[:id]).assimilate(victims.map {|v| Subject.get_or_die(v[:id])})

    json_response(:status => "OK")
  end

end
