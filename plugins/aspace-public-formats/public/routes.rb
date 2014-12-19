ArchivesSpacePublic::Application.routes.draw do

  scope AppConfig[:public_prefix] do
  
    match('/repositories/:repo_id/:type/:id/format/:format' => 'public_formats#generate', :via => [:get])

  end

end
