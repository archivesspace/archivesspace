Sequel.migration do
  up do
    create_table(:ark_minter) do
      primary_key :id
      Integer :repository, :unique => true, :null => false
      String :template, :default => '.zd', :null => false
      TextBlobField :state, :null => false
    end

    alter_table(:repository) do
      add_column(:ark_template, String, :default => '.zd')
    end
  end
  down do
    drop_table(:ark_minter)

    alter_table(:repository) do
      drop_column(:ark_template)
    end
  end
end
