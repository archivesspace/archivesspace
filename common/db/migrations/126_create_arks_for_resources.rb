require_relative 'utils'

# populates the ark_name table with records for existing
# resources, accessions, and digital objects
Sequel.migration do
  up do
    $stderr.puts("Adding Resource ARK ids")
    self[:resource].select(:id).each do |r|
      self[:ark_name].insert(:resource_id      => r[:id],
                                   :created_by       => 'admin',
                                   :last_modified_by => 'admin',
                                   :create_time      => Time.now,
                                   :system_mtime     => Time.now,
                                   :user_mtime       => Time.now,
                                   :lock_version     => 0)
    end
  end
end
