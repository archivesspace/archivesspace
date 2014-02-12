require_relative 'utils'

Sequel.migration do

  up do
    records_supporting_external_documents = [:accession, :archival_object,
                                             :resource, :subject,
                                             :agent_person,
                                             :agent_family,
                                             :agent_corporate_entity,
                                             :agent_software,
                                             :rights_statement,
                                             :digital_object,
                                             :digital_object_component]

    records_supporting_external_documents.each do |record|
      many_to_many_table = "#{record}_external_document".intern

      # add columns to the external document table
      # and foreign key constraints
      alter_table(:external_document) do
        add_column("#{record}_id".intern, :integer, :null => true)
        add_foreign_key(["#{record}_id".intern], record, :key => :id)

        # add that a location is unique for a record
        add_unique_constraint(["#{record}_id".intern, :location], :unique => true, :name => "uniq_exdoc_#{record}")
      end

      # populate the id columns for existing external documents
      self[many_to_many_table].filter(Sequel.~("#{record}_id".intern => nil)).all do |row|
        self[:external_document].
          filter(:id => row[:external_document_id]).
          update("#{record}_id".intern => row["#{record}_id".intern])
      end

      # drop the old many-to-many table
      drop_table(many_to_many_table)
    end

  end


  down do
  end

end

