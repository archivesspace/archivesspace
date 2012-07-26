class ArchivesSpaceService < Sinatra::Base

  post '/repository' do
    ensure_params ["repository" => {:doc => "The repository to create (JSON)"}]

    repository = JSONModel(:repository).from_json(params[:repository])

    db_repo = Repository.new(repository.to_hash)

    created = db_repo.save
    json_response({:status => "Created", :id => created[:id]})
  end


  get '/repository/:id' do
    repo = Repository[params[:id]]
    JSONModel(:repository).from_sequel(repo).to_json
  end

  get '/repository' do
    result = []

    Repository.each do |r|
      result << {:id => r.id, :repo_id => r.repo_id, :description => r.description}
    end

    json_response(result)
  end

end
