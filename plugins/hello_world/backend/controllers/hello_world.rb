class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/helloworld')
    .description("Hello World!")
    .params(["who", String, "Someone to say hello to", :default => 'Anonymous'])
    .permissions([])
    .returns([200, "{'reply', 'Hello (who)!'}"]) \
  do
    WhoSaidHello.create_from_json(JSONModel(:hello_world).from_hash({:who => params[:who]}))
    json_response('reply' => "Hello #{params[:who]}!")
  end


  Endpoint.get('/whosaidhello')
    .description("Get a list of who has said hello")
    .permissions([])
    .returns([200, "[(:hello_world)]"]) \
  do
    handle_unlimited_listing(WhoSaidHello)
  end

end
