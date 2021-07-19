require_relative 'utils'

Sequel.migration do
  up do

    TYPE_ID_SINGLE = get_enum_value_id("date_type_structured", "single")
    TYPE_ID_RANGE = get_enum_value_id("date_type_structured", "range")

    alter_table(:structured_date_label) do
      add_column(:date_type_structured, String, :null => false, :default => "none")
    end

    self[:structured_date_label].where(:date_type_structured_id => TYPE_ID_SINGLE).update(:date_type_structured => "single")
    self[:structured_date_label].where(:date_type_structured_id => TYPE_ID_RANGE).update(:date_type_structured => "range")

    alter_table(:structured_date_label) do
      drop_column(:date_type_structured_id)
    end
  end
end
