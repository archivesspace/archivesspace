class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/helloworld')
    .description("Hello World!")
    .params(["name", String, "Someone to say hello to", :default => 'Anonymous'])
    .nopermissionsyet
    .returns([200, "{'reply', 'Hello (name)!'}"]) \
  do
    WhoSaidHello.create_from_json(JSONModel(:hello_world).from_hash({:name => params[:name]}))
    json_response('reply' => "Hello #{params[:name]}!")
  end


  Endpoint.get('/whosaidhello')
    .description("Get a list of who has said hello")
    .permissions([])
    .returns([200, "[(:hello_world)]"]) \
  do
    handle_unlimited_listing(WhoSaidHello)
  end

end
