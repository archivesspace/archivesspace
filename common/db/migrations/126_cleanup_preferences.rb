require_relative 'utils'
require 'json'

Sequel.migration do
  up do

    self[:preference].each do |pref|

      parsed = JSON.parse(pref[:defaults])

      # Remove all existing langmaterials from the note_order array following ANW-697
      if parsed['note_order']&.include?('langmaterial')
        parsed['note_order'].delete('langmaterial')
        self[:preference].filter(:id => pref[:id]).update(
          :defaults => JSON.dump(parsed).to_sequel_blob,
          :system_mtime => Time.now
        )
      end

      # Remove any resource browse columns set to language following ANW-697
      (1..5).to_a.each do |n|
        if parsed.key?("resource_browse_column_#{n}") && parsed["resource_browse_column_#{n}"].include?('language')
          parsed.delete("resource_browse_column_#{n}")
          self[:preference].filter(:id => pref[:id]).update(
            :defaults => JSON.dump(parsed).to_sequel_blob,
            :system_mtime => Time.now
          )
        end
      end

    end

  end
end
