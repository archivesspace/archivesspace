class ArchivesSpaceService < Sinatra::Base

  post '/repo/:repo_id/accession' do
    ensure_params ["repo_id" => {:doc => "The ID of the repository containing the accession"},
                   "accession" => {:doc => "The accession to create (JSON)"}]

    accession = JSONModel(:accession).from_json(params[:accession])

    repo = Repository[:repo_id => params[:repo_id]]
    acc = repo.create_accession(accession)

    "Created"
  end


  get '/repo/:repo_id/accession/*/*/*/*' do
    ensure_params ["repo_id" => {:doc => "The ID of the repository containing the accession"},
                   "splat" => {:doc => "The accession ID"}]

    repo = Repository[:repo_id => params[:repo_id]]

    acc = repo.find_accession(params[:splat])

    JSONModel(:accession).from_hash(acc.values).to_json
  end

end
