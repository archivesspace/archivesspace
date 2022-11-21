require_relative 'utils'

Sequel.migration do

  up do
    self[:enumeration_value].update(value: Sequel.trim(:value))
  end

  down do
  end

end
