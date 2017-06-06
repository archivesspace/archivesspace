require_relative 'utils'
require 'digest/sha1'

Sequel.migration do

  up do
    # Add our new column
    alter_table(:resource) do
      add_column(:finding_aid_sponsor_sha1, String, :null => true, :index => true)
    end

    # Populate it
    self.transaction do
      self[:resource].exclude(:finding_aid_sponsor => nil).select(:id, :finding_aid_sponsor).each do |row|
        self[:resource].filter(:id => row[:id])
          .update(:finding_aid_sponsor_sha1 => Digest::SHA1.hexdigest(row[:finding_aid_sponsor]))
      end
    end
  end


  down do
    alter_table(:resource) do
      drop_column(:finding_aid_sponsor_sha1)
    end
  end

end

