Sequel.migration do

  up do
    alter_table(:classification_term) do
      TextField :display_string, :null => true
    end

    self[:classification_term].update(:display_string => :title)

    alter_table(:classification_term) do
      set_column_not_null :display_string
    end

  end


  down do
  end

end

