Sequel.migration do

  up do
    alter_table(:external_document) do
      add_column( :assessment_id, :integer, :null => true )
      add_foreign_key([:assessment_id], :event, :key => :id, :name => 'assessment_external_document_fk')
    end
  end

end
