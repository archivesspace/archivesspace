class ArchivesSpaceService < Sinatra::Base

  post '/repositories' do
    ensure_params ["repository" => {
                     :doc => "The repository to create",
                     :type => JSONModel(:repository),
                     :body => true
                   }]

    repo = Repository.create(params[:repository].to_hash)
    created_response(repo[:id])
  end


  get '/repositories/:id' do
    repo = Repository[params[:id]]
    JSONModel(:repository).from_sequel(repo).to_json
  end

  get '/repositories' do
    result = []

    Repository.each do |r|
      result << {:id => r.id, :repo_id => r.repo_id, :description => r.description}
    end

    json_response(result)
  end

end
