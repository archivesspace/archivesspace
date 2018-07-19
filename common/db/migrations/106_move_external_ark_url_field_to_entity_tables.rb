require_relative 'utils'

# moves external_id field from the ARKs table to resource, accession and digital objects tables, respectively.
Sequel.migration do
  up do
    alter_table(:ark_identifier) do
      drop_column(:external_id)
    end

    alter_table(:resource) do
      add_column(:external_ark_url, String)
    end

    alter_table(:accession) do
      add_column(:external_ark_url, String)
    end

    alter_table(:digital_object) do
      add_column(:external_ark_url, String)
    end
  end
end