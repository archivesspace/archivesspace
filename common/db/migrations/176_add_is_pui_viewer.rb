require_relative 'utils'

Sequel.migration do

  up do
    $stderr.puts("Add PUI viewer boolean")
    alter_table(:user) do
      add_column(:is_pui_viewer, Integer, :default => 0)
    end
  end

  down do
    alter_table(:user) do
      drop_column(:is_pui_viewer)
    end
  end

end
