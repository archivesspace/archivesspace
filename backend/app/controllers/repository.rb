class ArchivesSpaceService < Sinatra::Base

  post '/repo' do
    ensure_params ["id" => {:doc => "The ID of the repository to create"},
                   "description" => {:doc => "A description of the repository you're creating"}]

    Repository.create(:repo_id => params[:id],
                      :description => params[:description])

    "Created"
  end


  get '/repo' do
    result = []

    Repository.each do |r|
      result << {:id => r.repo_id, :description => r.description}
    end

    json_response(result)
  end

end
