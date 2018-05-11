require_relative 'utils'

# populates the ark_identifier table with records for existing 
# resources, accessions, and digital objects
Sequel.migration do
  up do
    alter_table(:ark_identifier) do
      add_column(:external_id, String)
      add_column(:lock_version, Integer)
    end
    
    # resources
    self[:resource].select(:id).each do |r|
      self[:ark_identifier].insert(:resource_id      => r[:id],
                                   :created_by       => 'admin',
                                   :last_modified_by => 'admin',
                                   :create_time      => Time.now,
                                   :system_mtime     => Time.now,
                                   :user_mtime       => Time.now,
                                   :lock_version     => 0)
    end

    # accessions
    self[:accession].select(:id).each do |r|
      self[:ark_identifier].insert(:accession_id     => r[:id],
                                   :created_by       => 'admin',
                                   :last_modified_by => 'admin',
                                   :create_time      => Time.now,
                                   :system_mtime     => Time.now,
                                   :user_mtime       => Time.now,
                                   :lock_version     => 0)
    end

    # digital objects
    self[:digital_object].select(:id).each do |r|
      self[:ark_identifier].insert(:digital_object_id => r[:id],
                                   :created_by        => 'admin',
                                   :last_modified_by  => 'admin',
                                   :create_time       => Time.now,
                                   :system_mtime      => Time.now,
                                   :user_mtime        => Time.now,
                                   :lock_version      => 0)
    end
  end
end