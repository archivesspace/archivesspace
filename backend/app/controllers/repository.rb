class ArchivesSpaceService < Sinatra::Base

  post '/repositories' do
    ensure_params ["repository" => {
                     :doc => "The repository to create",
                     :type => JSONModel(:repository),
                     :body => true
                   }]

    repo = Repository.create_from_json(params[:repository])
    created_response(repo[:id])
  end


  get '/repositories/:id' do
    Repository.to_jsonmodel(Repository.get_or_die(params[:id]),
                            :repository).to_json
  end


  get '/repositories' do
    result = []

    Repository.each do |r|
      result << {:id => r.id, :repo_code => r.repo_code, :description => r.description}
    end

    json_response(result)
  end

end
