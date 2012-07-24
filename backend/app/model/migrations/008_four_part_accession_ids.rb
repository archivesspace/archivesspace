Sequel.migration do
  up do
    alter_table(:accessions) do

      add_column :accession_id_0, String, :null => false, :default => ""
      add_column :accession_id_1, String, :null => false, :default => ""
      add_column :accession_id_2, String, :null => false, :default => ""
      add_column :accession_id_3, String, :null => false, :default => ""

      drop_column :accession_id

      add_index [:accession_id_0,
                 :accession_id_1,
                 :accession_id_2,
                 :accession_id_3],
      :unique => true,
      :name => "unique_acc_id"
    end
  end

  down do
    alter_table(:accessions) do

      add_column :accession_id, :string, :null => false, :unique => true

      drop_column :accession_id_0
      drop_column :accession_id_1
      drop_column :accession_id_2
      drop_column :accession_id_3

      drop_index [:accession_id_0, :accession_id_1, :accession_id_2, :accession_id_3]
    end

  end
end
