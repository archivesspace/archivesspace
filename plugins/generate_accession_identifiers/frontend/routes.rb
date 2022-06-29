ArchivesSpace::Application.routes.draw do
  [AppConfig[:frontend_proxy_prefix], AppConfig[:frontend_prefix]].uniq.each do |prefix|

  scope prefix do
  match('/plugins/generate_accession_identifier/generate' => 'generate_accession_identifiers#generate',
        :via => [:post])
  end
 end
end
