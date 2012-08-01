class ArchivesSpaceService < Sinatra::Base


  post '/accessions/:accession_id' do
    ensure_params ["accession_id" => {
                     :doc => "The accession ID to update",
                     :type => Integer
                   },
                   "accession" => {
                     :doc => "The accession data to update (JSON)",
                     :type => JSONModel(:accession),
                     :body => true
                   }]

    acc = Accession.get_or_die(params[:accession_id])

    acc.update_from_json(params[:accession])

    json_response({:status => "Updated", :id => acc[:id]})
  end


  post '/accessions', :operation => :delete do
    "Deleting: #{params.inspect}"
  end


  post '/accessions' do
    ensure_params ["accession" => {
                     :doc => "The accession to create (JSON)",
                     :type => JSONModel(:accession),
                     :body => true
                   }]

    accession = Accession.create_from_json(params[:accession])

    created_response(accession[:id], params[:accession]._warnings)
  end


  get '/accessions' do
    Accession.all.collect {|acc| acc.values}.to_json
  end


  get '/accessions/:accession_id' do
    ensure_params ["accession_id" => {:doc => "The accession ID", :type => Integer}]

    Accession.to_jsonmodel(params[:accession_id], :accession).to_json
  end
end
