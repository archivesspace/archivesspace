require 'db/migrations/utils'

Sequel.migration do
  up do
    alter_table(:repository) do
      add_column(:oai_is_disabled, Integer)
      add_column(:oai_sets_available, String, text: true)
    end
  end

end
