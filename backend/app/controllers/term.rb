class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/terms')
    .description("Get a list of Terms matching a prefix")
    .params(["q", String, "The prefix to match"])
    .nopermissionsyet
    .returns([200, "[(:term)]"]) \
  do
    query = params[:q].gsub(/[%]/, '').downcase
    handle_listing(Term, 1, 20, 0, Sequel.like(Sequel.function(:lower, :term),
                                               "#{query}%"))
  end

end
