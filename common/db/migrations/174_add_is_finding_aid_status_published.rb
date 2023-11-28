require_relative 'utils'

Sequel.migration do
  up do
    $stderr.puts("Add is_finding_aid_status_published to resource")
    alter_table(:resource) do
      add_column(:is_finding_aid_status_published, Integer, :default => 1)
    end
  end
end
