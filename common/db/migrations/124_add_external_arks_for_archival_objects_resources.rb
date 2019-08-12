require_relative 'utils'

Sequel.migration do
  up do
    $stderr.puts("Adding External ARK URLs for Archival Objects and Resources")
    alter_table(:archival_object) do
      add_column(:external_ark_url, String)
    end
    alter_table(:resource) do
      add_column(:external_ark_url, String)
    end
  end

  down do
  end
end
