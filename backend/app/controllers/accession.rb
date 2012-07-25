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
    ensure_params ["repo_id" => {:doc => "The ID of the repository containing the accession", :type => Integer},
                   "accession" => {:doc => "The accession to create (JSON)"}]

    accession = JSONModel(:accession).from_json(params[:accession])

    repo = Repository[:id => params[:repo_id]]
    id = repo.create_accession(accession)

    json_response({:status => "Created", :id => id})
  end


  get '/repo/:repo_id/accessions' do
    ensure_params ["repo_id" => {:doc => "The ID of the repository containing the accession", :type => Integer}]

    repo = Repository[:id => params[:repo_id]]

    Accession.all.collect {|acc| acc.values}.to_json
  end


  get '/repo/:repo_id/accession/:accession_id' do
    ensure_params ["repo_id" => {:doc => "The ID of the repository containing the accession", :type => Integer},
                   "accession_id" => {:doc => "The accession ID", :type => Integer}]

    repo = Repository[:id => params[:repo_id]]

    acc = Accession[params[:accession_id]]

    if acc
      JSONModel(:accession).from_sequel(acc).to_json
    else
      raise NotFoundException.new("Accession not found")
    end
  end
end
