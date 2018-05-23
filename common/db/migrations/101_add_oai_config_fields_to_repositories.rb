require 'db/migrations/utils'

Sequel.migration do
  up do
    alter_table(:repository) do
      add_column(:oai_is_disabled, TrueClass)
      add_column(:oai_sets_available, String, text: true)
    end
  end

end
