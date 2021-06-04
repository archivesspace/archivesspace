# frozen_string_literal: true

require_relative 'utils'

Sequel.migration do
  up do
    warn('Adding Limit to Custom Report Template')
    alter_table(:custom_report_template) do
      add_column(:limit, Integer)
    end
  end
  down do
  end
end
