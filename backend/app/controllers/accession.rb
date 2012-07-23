class ArchivesSpaceService < Sinatra::Base

  post '/repo/:repo_id/accession' do
    ensure_params ["repo_id" => {:doc => "The ID of the repository containing the accession"},
                   "accession" => {:doc => "The accession to create (JSON)"}]

    accession = JSON(params[:accession])

    repo = Repository[:repo_id => params[:repo_id]]

    # FIXME: I'm just asking for security problems here.  We're still trying to
    # nail down just how we'll handle validation of the different record types.
    # Suffice to say, it'll be better than this :)
    acc = repo.create_accession(accession)

    "Created"
  end


  get '/repo/:repo_id/accession/:accession_id' do
    ensure_params ["repo_id" => {:doc => "The ID of the repository containing the accession"},
                   "accession_id" => {:doc => "The accession to retrieve (JSON)"}]

    repo = Repository[:repo_id => params[:repo_id]]

    acc = repo.find_accession(:accession_id => params[:accession_id])

    JSON(acc.values)
  end

end
