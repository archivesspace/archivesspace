require 'db/migrations/utils'

Sequel.migration do
  up do
    alter_table(:oai_config) do
      add_column(:repo_set_codes, String, text: true)
      add_column(:repo_set_description, String)
      add_column(:sponsor_set_names, String, text: true)
      add_column(:sponsor_set_description, String)
    end

    # populate new fields with default values
    self[:oai_config].update(:repo_set_codes => "[]", 
                             :sponsor_set_names => "[]",
                             :repo_set_description => "",
                             :sponsor_set_description => "")
  end

end
