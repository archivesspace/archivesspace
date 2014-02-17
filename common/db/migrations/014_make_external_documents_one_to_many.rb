require_relative 'utils'
require 'digest/sha1'

Sequel.migration do

  up do

    # add a location_hash column
    add_column :external_document, :location_sha1, String

    records_supporting_external_documents = [:accession,
                                             :archival_object,
                                             :resource,
                                             :subject,
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
        constraint_name = "uniq_exdoc_#{record.to_s.split("_").map{|s| s[0,3]}.join("_")}"
        add_unique_constraint(["#{record}_id".intern, :location_sha1], :unique => true, :name => constraint_name)
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

    # populate the location_hash column
    self[:external_document].all.each do |row|
      hash = Digest::SHA1.hexdigest(row[:location])
      self[:external_document].filter(:id => row[:id]).update(:location_sha1 => hash)
    end

  end


  down do
    drop_table(:external_document)
  end

end

