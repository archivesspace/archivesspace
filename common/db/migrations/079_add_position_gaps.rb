Sequel.migration do

  up do
    alter_table(:archival_object) do
      drop_index([:parent_name, :position], :unique => true, :name => "uniq_ao_pos")
    end

    alter_table(:digital_object_component) do
      drop_index([:parent_name, :position], :unique => true, :name => "uniq_do_pos")
    end

    alter_table(:classification_term) do
      drop_index([:parent_name, :position], :unique => true, :name => "uniq_ct_pos")
    end

    self.transaction do
      tables = [:archival_object, :digital_object_component, :classification_term]

      tables.each do |table|
        # Find any positions that were NULL and give them a proper value.  Since
        # they would have sorted to the top, we'll arbitrarily assign them a
        # number starting from 0.

        parents_with_nulls = self[table].filter(:position => nil).select(:parent_name).distinct.map {|row| row[:parent_name]}

        parents_with_nulls.each do |parent_name|
          null_records = self[table].filter(:parent_name => parent_name).filter(:position => nil)

          # Make sure we have some space for our new positions
          self[table].filter(:parent_name => parent_name).update(:position => Sequel.lit("position + #{null_records.count}"))

          null_records.select(:id).each_with_index do |record, new_position|
            self[table].filter(:id => record[:id]).update(:position => new_position)
          end
        end
      end

      # Multiply all positions by 1000 to introduce gaps.  This will reduce the
      # amount of shuffling we need to do when repositioning records.
      tables.each do |table|
        self[table].update(:position => Sequel.lit('position * 1000'))
      end
    end

    alter_table(:archival_object) do
      add_index([:parent_name, :position], :unique => true, :name => "uniq_ao_pos")
      set_column_not_null(:position)
    end

    alter_table(:digital_object_component) do
      add_index([:parent_name, :position], :unique => true, :name => "uniq_do_pos")
      set_column_not_null(:position)
    end

    alter_table(:classification_term) do
      add_index([:parent_name, :position], :unique => true, :name => "uniq_ct_pos")
      set_column_not_null(:position)
    end
  end


  down do
  end

end
