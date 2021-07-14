require_relative 'utils'

Sequel.migration do
  up do
    $stderr.puts("Add active status to user")
    alter_table(:user) do
      add_column(:is_active_user, Integer, :default => 1)
    end
  end
end
