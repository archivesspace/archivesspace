# frozen_string_literal: true

require_relative 'utils'

Sequel.migration do
  up do
    warn('Adding note to Container Profile')
    alter_table(:container_profile) do
      add_column(:notes, String)
    end
  end

  down do
  end
end
