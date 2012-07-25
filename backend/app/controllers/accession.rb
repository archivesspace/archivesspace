class ArchivesSpaceService < Sinatra::Base

  post '/repo/:repo_id/accession/*' do
    ensure_params ["repo_id" => {:doc => "The ID of the repository containing the accession"},
                   "splat" => {:doc => "The accession ID"},
                   "accession" => {:doc => "The accession data to update (JSON)"}]

    acc_id = params[:splat][0].split("/", 4)
    
    repo = Repository[:repo_id => params[:repo_id]]
    
    acc = repo.find_accession(acc_id)
    acc.update(JSONModel(:accession).from_json(params[:accession]).to_hash)

    "Updated"
  end

  post '/repo/:repo_id/accession' do
    ensure_params ["repo_id" => {:doc => "The ID of the repository containing the accession"},
                   "accession" => {:doc => "The accession to create (JSON)"}]

    accession = JSONModel(:accession).from_json(params[:accession])

    repo = Repository[:repo_id => params[:repo_id]]
    acc = repo.create_accession(accession)

    "Created"
  end

  get '/repo/:repo_id/accessions' do
    ensure_params ["repo_id" => {:doc => "The ID of the repository containing the accession"}]

    repo = Repository[:repo_id => params[:repo_id]]

    repo.all_accessions.collect {|acc| acc.values}.to_json
  end

  get '/repo/:repo_id/accession/:accession_id' do
    ensure_params ["repo_id" => {:doc => "The ID of the repository containing the accession"},
                   "accession_id" => {:doc => "The accession ID"}]

    repo = Repository[:repo_id => params[:repo_id]]

    acc = repo.find_accession(params[:accession_id])

    JSONModel(:accession).from_hash(acc.values).to_json
  end

end
