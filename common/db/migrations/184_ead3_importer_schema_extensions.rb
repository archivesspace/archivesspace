Sequel.migration do
   up do
     new_columns = [:agent, :agent_type, :type]
     old_columns = self[:revision_statement].columns
     if new_columns.none? { |col| old_columns.include?(col) }
       alter_table(:revision_statement) do
         add_column(:agent, String)
         add_column(:agent_type, String)
         add_column(:type, String)
       end
     end
     alter_table(:instance) do
       set_column_allow_null :instance_type_id
     end
   end
 end
