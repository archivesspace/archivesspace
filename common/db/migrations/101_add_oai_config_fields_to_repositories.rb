require 'db/migrations/utils'

Sequel.migration do
  up do
  	# add columns
    alter_table(:repository) do
      add_column(:oai_is_disabled, Integer)
      add_column(:oai_sets_available, String, text: true)

      set_column_default :oai_is_disabled, 0
    end

    # populate oai_sets_available column with serialized version of empty string
    self[:repository].update(:oai_sets_available => "[]", :oai_is_disabled => 0)
  end

end
