require_relative 'utils'

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
      drop_index([:parent_name, :title_sha1], :unique => true)
      drop_index([:parent_name, :identifier], :unique => true)
    end

    [:archival_object, :classification_term, :digital_object_component].each do |t|
      # parent_name no longer needed
      alter_table(t) do
        drop_column(:parent_name)
      end
    end

    alter_table(:archival_object) do
      add_column(:generated_parent_id, :integer, generated_always_as: Sequel.case({{parent_id: nil}=>0}, :parent_id), generated_type: :stored)
      add_index([:root_record_id, :generated_parent_id, :position], :unique => true, :name => "uniq_ao_pos")
      set_column_not_null(:position)
    end

    alter_table(:digital_object_component) do
      add_column(:generated_parent_id, :integer, generated_always_as: Sequel.case({{parent_id: nil}=>0}, :parent_id), generated_type: :stored)
      add_index([:root_record_id, :generated_parent_id, :position], :unique => true, :name => "uniq_do_pos")
      set_column_not_null(:position)
    end

    alter_table(:classification_term) do
      add_column(:generated_parent_id, :integer, generated_always_as: Sequel.case({{parent_id: nil}=>0}, :parent_id), generated_type: :stored)
      add_index([:root_record_id, :generated_parent_id, :position], :unique => true, :name => "uniq_ct_pos")
      set_column_not_null(:position)
      add_index([:root_record_id, :generated_parent_id, :title_sha1], :unique => true, :name => "uniq_title")
      add_index([:root_record_id, :generated_parent_id, :identifier], :unique => true, :name => "uniq_identifier")
    end

  end

  down do
  end

end
