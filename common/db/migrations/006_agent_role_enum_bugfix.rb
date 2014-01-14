require_relative 'utils'

Sequel.migration do

  up do
    enum = self[:enumeration].filter(:name => 'linked_agent_role').select(:id)
    enumeration_values = self[:enumeration_value].filter(:enumeration_id => enum).all

    self.transaction do
      enumeration_values.each do |value|
        self[:linked_agents_rlshp].filter(:role => value[:value],
                                          :role_id => nil).
                                   update(:role => nil,
                                          :role_id => value[:id])
      end
    end

    if self[:linked_agents_rlshp].filter(Sequel.~(:role => nil)).count == 0
      alter_table(:linked_agents_rlshp) do
        drop_column(:role)
      end
    else
      $stderr.puts("WARNING: we tried to drop the column " +
                   "'linked_agents_rlshp.role' as a part of " +
                   "migration 006_agent_role_enum_bugfix.rb but " +
                   "there's still data in it.  Please contact " +
                   "support as your migration may be incomplete.")
    end
  end


  down do
    # No going back!
  end

end

