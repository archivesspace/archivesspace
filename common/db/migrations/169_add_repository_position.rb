require_relative 'utils'

Sequel.migration do
  up do
    alter_table(:repository) do
      add_column(:position, :integer, :unique => true)
    end

    self[:repository].sort { |r| r[:id] }.each_with_index { |r, i|
      self[:repository].filter(id: r[:id]).update(position: i)
    }

    alter_table(:repository) do
      set_column_not_null :position
      set_column_default :position, -1
    end
  end
end
