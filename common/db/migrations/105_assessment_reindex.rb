require_relative 'utils'

Sequel.migration do

  up do
    now = Time.now
    [:assessment].each do |table|
      self[table].update(:system_mtime => now)
    end
  end


  down do
  end

end

