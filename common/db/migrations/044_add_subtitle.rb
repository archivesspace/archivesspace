require_relative 'utils'

Sequel.migration do

  up do
    alter_table(:resource) do
     TextField :finding_aid_subtitle 
    end
  end


  down do
    alter_table(:resource) do
      drop_column(:finding_aid_subtitle)
    end
  end

end

