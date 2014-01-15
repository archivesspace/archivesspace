require_relative 'utils'

Sequel.migration do

  up do
    alter_table(:user_defined) do
      [:enum_1_id, :enum_2_id, :enum_3_id, :enum_4_id].each do |enum|
        add_column(enum, :integer, :null => true)
        add_foreign_key([enum], :enumeration_value, :key => :id)
      end
    end

    (1..4).each do |n|
      create_editable_enum("user_defined_enum_#{n}", ["novalue"])
    end
  end

  down do
    # no down provided as we don't really support down migrations
    # except those down to 0 (db:nuke) and there's nothing to do
    # for this migration to support a nuke.
  end

end
