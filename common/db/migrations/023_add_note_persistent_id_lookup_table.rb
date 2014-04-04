require_relative 'utils'

Sequel.migration do

  up do
    create_table(:note_persistent_id) do
      primary_key :id

      Integer :note_id, :null => false
      String :persistent_id, :null => false
      String :parent_type, :null => false
      Integer :parent_id, :null => false
    end

    alter_table(:note_persistent_id) do
      add_foreign_key([:note_id], :note, :key => :id, :on_delete => :cascade)
    end
  end

  down do
    drop_table(:note_persistent_id)
  end

end

