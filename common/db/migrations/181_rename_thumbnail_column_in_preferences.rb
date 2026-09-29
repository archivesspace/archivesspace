require 'json'

Sequel.migration do
  up do
    # The "Thumbnail Image" search/browse column (representative_file_version) is now "Thumbnail" (thumbnail)
    self[:preference]
      .select(:id, :defaults)
      .all
      .each do |row|
      preference_data = JSON.parse(row[:defaults])
      keys_to_rename = preference_data.select { |key, value|
        key =~ /_column_[0-9]+$/ && value == 'representative_file_version'
      }.keys

      next if keys_to_rename.empty?

      keys_to_rename.each do |key|
        preference_data[key] = 'thumbnail'
      end

      self[:preference]
        .filter(:id => row[:id])
        .update(:defaults => JSON.dump(preference_data))
    end
  end

  down do
  end
end
