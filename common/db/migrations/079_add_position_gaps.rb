Sequel.migration do

  up do
    begin
    alter_table(:archival_object) do
      drop_index([:parent_name, :position], :unique => true, :name => "uniq_ao_pos")
    end
    alter_table(:digital_object_component) do
      drop_index([:parent_name, :position], :unique => true, :name => "uniq_do_pos")
    end
    alter_table(:classification_term) do
      drop_index([:parent_name, :position], :unique => true, :name => "uniq_ct_pos")
    end
    rescue
    end

    self.transaction do
      self[:archival_object].update(:position => Sequel.lit('position * 1000'))
      self[:digital_object_component].update(:position => Sequel.lit('position * 1000'))
      self[:classification_term].update(:position => Sequel.lit('position * 1000'))
    end

    alter_table(:archival_object) do
      add_index([:parent_name, :position], :unique => true, :name => "uniq_ao_pos")
    end
    alter_table(:digital_object_component) do
      add_index([:parent_name, :position], :unique => true, :name => "uniq_do_pos")
    end
    alter_table(:classification_term) do
      add_index([:parent_name, :position], :unique => true, :name => "uniq_ct_pos")
    end
  end


  down do
  end

end
