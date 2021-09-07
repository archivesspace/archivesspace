require_relative 'utils'

# This migration is very similair to 132 -- except that it appends the certainty label on to the display string
Sequel.migration do

  up do
    $stderr.puts("Reconstructing display strings for archival objects and digital object components with a certainty value")

    bulk_date = self[:enumeration_value].filter(:value => 'bulk').get(:id)

    ['archival_object', 'digital_object_component'].each do |component_type|
      component_id = self[:date].group_and_count(:"#{component_type}_id").having {count.function.* > 1}.select(:"#{component_type}_id")
      components_with_dates = self[:date].where(:"#{component_type}_id" => component_id).select(:"#{component_type}_id")

      components_with_dates.distinct.each do |component_with_dates|
        components = self[:"#{component_type}"].where(id: component_with_dates[:"#{component_type}_id"])
        # Save the old display string for later logging
        old_display_string = self[:"#{component_type}"].where(id: component_with_dates[:"#{component_type}_id"]).get(:display_string)
        components.each do |component|
          date_recs = self[:date].where("#{component_type}_id": component[:id])

          # skip unless record has a date where certainty is defined
          next unless date_recs.inject(false) {|memo, d| memo || !d[:certainty_id].nil? }

          enum_id_approximate = get_enum_value_id("date_certainty", "approximate")
          enum_id_inferred = get_enum_value_id("date_certainty", "inferred")
          enum_id_questionable = get_enum_value_id("date_certainty", "questionable")

          translated_list = {}
          translated_list[enum_id_approximate] = "Approximate"
          translated_list[enum_id_inferred] = "Inferred"
          translated_list[enum_id_questionable] = "Questionable"

          date_parts = []
          # Date logic used in archival object and digital object component model autogenerate proc
          date_recs.each do |date_rec|


            if date_rec[:certainty_id]
              dct = translated_list[date_rec[:certainty_id]]

              certainty_str = " (#{dct})"
            else
              certainty_str = ""
            end

            $stderr.puts date_rec['certainty_str']

            if date_rec[:expression] != nil
              date_parts << (date_rec[:date_type_id] == bulk_date ? "bulk: #{date_rec[:expression]}" : date_rec[:expression])
            elsif date_rec[:begin] && date_rec[:end]
              date_parts << (date_rec[:date_type_id] == bulk_date ? "bulk: #{date_rec[:begin]} - #{date_rec[:end]} + certainty_str" : "#{date_rec[:begin]} - #{date_rec[:end] + certainty_str}")
            else
              date_parts << (date_rec[:date_type_id] == bulk_date ? "bulk: #{date_rec[:begin] + certainty_str}" : date_rec[:begin] + certainty_str)
            end
          end

          date_label = date_parts.join(", ")
          # Title logic used in archival object and digital object component model autogenerate proc
          display_string = component[:title] || component[:label] || ""
          display_string += ", " if component[:title] || component[:label]
          display_string += date_label if date_label
          # Update the display string to include all dates
          self[:"#{component_type}"].where(id: component[:id]).update(:display_string => display_string)
          new_display_string = self[:"#{component_type}"].where(id: component[:id]).get(:display_string)
          $stderr.puts "Updating display string for #{component_type} #{component[:id]}"
          $stderr.puts "Original display string: #{old_display_string}"
          $stderr.puts "New display string: #{new_display_string}"
        end
      end
    end
  end


  down do
  end

end
