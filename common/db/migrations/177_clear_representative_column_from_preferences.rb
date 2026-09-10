require 'json'

Sequel.migration do
  up do
    self[:preference]
      .select(:id, :defaults)
      .each do |row|
      preference_data = JSON.parse(row[:defaults])
      keys_to_delete = []
      preference_data.each do |key, value|
        if key =~ /_column_[0-9]+$/ and value == 'representative_file_version'
          keys_to_delete << key
        end
      end

      unless keys_to_delete.empty?
        keys_to_delete.each do |key|
          preference_data.delete(key)
        end

        self[:preference]
          .filter(:id => row[:id])
          .update(:defaults => JSON.dump(preference_data))
      end
    end
  end
end
