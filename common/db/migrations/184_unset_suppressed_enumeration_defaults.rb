Sequel.migration do
  up do
    self[:enumeration]
      .filter(:default_value => self[:enumeration_value].filter(:suppressed => 1).select(:id))
      .update(:default_value => nil, :system_mtime => Time.now)
  end

  down do
  end
end
