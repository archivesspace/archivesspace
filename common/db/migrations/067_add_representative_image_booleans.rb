require_relative 'utils'

Sequel.migration do

  up do
    [:file_version, :instance].each do |table|
      alter_table(table) do
        add_column(:is_representative, Integer, :null => true, :default => nil)
      end
    end

    alter_table(:instance) do
      add_unique_constraint([:is_representative, :resource_id],
                              :name => "resource_one_representative_instance")
      add_unique_constraint([:is_representative, :archival_object_id],
                              :name => "component_one_representative_instance")
    end

    alter_table(:file_version) do
      add_unique_constraint([:is_representative, :digital_object_id],
                              :name => "digital_object_one_representative_file_version")
      add_column(:caption, String, :null => true)

    end
  end


  down do
  end

end

