require 'db/migrations/utils'

Sequel.migration do
  up do
    $stderr.puts("Populate OAI set names with default values")
    alter_table(:oai_config) do
      add_column(:repo_set_name, String)
      add_column(:sponsor_set_name, String)
    end

    # populate new fields with default values
    self[:oai_config].update(:repo_set_name => "repository_set",
                             :sponsor_set_name => "sponsor_set")
  end

end
