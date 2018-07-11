require_relative 'utils'

Sequel.migration do

  up do

    # Find null values
    nulls = self[:archival_object].where(:publish => nil)

    # If null update to unpublished/false/0
    if nulls
      nulls.update(:publish => 0, :system_mtime => Time.now)
    end

    # Change the column to not allow null for all future archival_objects and update the default to unpublished/false/0
    alter_table(:archival_object) do
      set_column_default :publish, 0
      set_column_not_null :publish
    end

  end

end
