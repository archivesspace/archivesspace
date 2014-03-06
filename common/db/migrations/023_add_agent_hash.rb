require_relative 'utils'
require 'digest/sha1'

Sequel.migration do

  up do

    # add a column for id'ing unique agents
    add_column :agent_person, :agent_sha1, String
    add_column :agent_family, :agent_sha1, String
    add_column :agent_corporate_entity, :agent_sha1, String
    add_column :agent_software, :agent_sha1, String

  end

  down do

    drop_column :agent_person, :agent_sha1
    drop_column :agent_family, :agent_sha1
    drop_column :agent_corporate_entity, :agent_sha1
    drop_column :agent_software, :agent_sha1
  end

end
