class ArchivesSpaceService < Sinatra::Base


  post '/repositories/:repo_id/accessions/:accession_id' do
    ensure_params ["accession_id" => {
                     :doc => "The accession ID to update",
                     :type => Integer
                   },
                   "accession" => {
                     :doc => "The accession data to update (JSON)",
                     :type => JSONModel(:accession),
                     :body => true
                   },
                   "repo_id" => {
                     :doc => "The repository ID",
                     :type => Integer,
                   }]

    acc = Accession.get_or_die(params[:accession_id])

    acc.update_from_json(params[:accession])

    json_response({:status => "Updated", :id => acc[:id]})
  end


  post '/repositories/:repo_id/accessions' do
    ensure_params ["accession" => {
                     :doc => "The accession to create (JSON)",
                     :type => JSONModel(:accession),
                     :body => true
                   },
                   "repo_id" => {
                     :doc => "The repository ID",
                     :type => Integer,
                   }]

    accession = Accession.create_from_json(params[:accession],
                                           :repo_id => params[:repo_id])
    created_response(accession[:id], params[:accession]._warnings)
  end


  get '/repositories/:repo_id/accessions' do
    ensure_params ["repo_id" => {
                     :doc => "The repository ID",
                     :type => Integer,
                   }]

    JSON(Accession.filter(:repo_id => params[:repo_id]).collect {|acc|
           Accession.to_jsonmodel(acc, :accession).to_hash})
  end


  get '/repositories/:repo_id/accessions/:accession_id' do
    ensure_params ["accession_id" => {:doc => "The accession ID", :type => Integer},
                   "repo_id" => {
                     :doc => "The repository ID",
                     :type => Integer,
                   }]

    Accession.to_jsonmodel(params[:accession_id], :accession).to_json
  end
end
