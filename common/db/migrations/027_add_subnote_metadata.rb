require_relative 'utils'

Sequel.migration do

  up do
    create_table(:subnote_metadata) do
      primary_key :id

      Integer :note_id, :null => false
      String :guid, :null => false

      Integer :publish
    end

    alter_table(:subnote_metadata) do
      add_foreign_key([:note_id], :note, :key => :id)
    end
  end

end

