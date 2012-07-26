class ArchivesSpaceService < Sinatra::Base

  post '/repo' do
    ensure_params ["repository" => {:doc => "The repository to create (JSON)"}]

    repository = JSONModel(:repository).from_json(params[:repository])

    db_repo = Repository.new(repository.to_hash)
    
    if db_repo.valid? then
      created = db_repo.save
      json_response({:status => "Created", :id => created[:id]})
    else
      json_response({:status => "Error", :errors=>db_repo.errors})
    end
  end

  get '/repo/:id' do
    repo = Repository[params[:id]]
    JSONModel(:repository).from_sequel(repo).to_json
  end
  
  get '/repo' do
    result = []

    Repository.each do |r|
      result << {:id => r.id, :repo_id => r.repo_id, :description => r.description}
    end

    json_response(result)
  end

end
