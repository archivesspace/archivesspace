class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/terms')
    .description("Get a list of Terms matching a prefix")
    .params(["q", String, "The prefix to match"])
    .permissions([])
    .returns([200, "[(:term)]"]) \
  do
    query = params[:q].gsub(/[%]/, '').downcase
    handle_listing(Term, {:page => 1, :page_size => 20, :modified_since => 0},
                   Sequel.like(Sequel.function(:lower, :term),
                               "#{query}%"))
  end

end
