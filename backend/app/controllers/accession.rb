class ArchivesSpaceService < Sinatra::Base


  post '/accessions/:accession_id' do
    ensure_params ["accession_id" => {:doc => "The accession ID to update", :type => Integer},
                   "accession" => {:doc => "The accession data to update (JSON)", :type => JSONModel(:accession)}]

    acc = Accession[params[:accession_id]]

    if acc
      acc.update(params[:accession].to_hash)
    else
      raise NotFoundException.new("Accession not found")
    end

    json_response({:status => "Updated", :id => acc[:id]})
  end


  post '/accessions', :operation => :delete do
    "Deleting: #{params.inspect}"
  end


  post '/accessions' do
    ensure_params ["repo_id" => {:doc => "The ID of the repository containing the accession", :type => Integer},
                   "accession" => {:doc => "The accession to create (JSON)", :type => JSONModel(:accession)}]

    repo = Repository[params[:repo_id]]
    id = repo.create_accession(params[:accession])

    created_response(id, params[:accession]._warnings)
  end


  get '/accessions' do
    ensure_params ["repo_id" => {:doc => "The ID of the repository containing the accession", :type => Integer}]

    repo = Repository[params[:repo_id]]

    Accession.all.collect {|acc| acc.values}.to_json
  end


  get '/accessions/:accession_id' do
    ensure_params ["accession_id" => {:doc => "The accession ID", :type => Integer}]

    acc = Accession[params[:accession_id]]

    if acc
      JSONModel(:accession).from_sequel(acc).to_json
    else
      raise NotFoundException.new("Accession not found")
    end
  end
end
