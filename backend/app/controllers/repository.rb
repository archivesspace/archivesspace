class ArchivesSpaceService < Sinatra::Base

  post '/repositories' do
    ensure_params ["repository" => {:doc => "The repository to create (JSON)", :type => JSONModel(:repository)}]

    db_repo = Repository.new(params[:repository].to_hash)

    created = db_repo.save
    created_response(created[:id])
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
