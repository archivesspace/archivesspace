require_relative 'utils'

Sequel.migration do

  up do
    $stderr.puts("Reconstructing display strings for archival objects and digital object components with multiple dates.")

    bulk_date = self[:enumeration_value].filter(:value => 'bulk').get(:id)

    ['archival_object', 'digital_object_component'].each do |component_type|
      component_id = self[:date].group_and_count(:"#{component_type}_id").having{count.function.* > 1}.select(:"#{component_type}_id")
      components_with_dates = self[:date].where(:"#{component_type}_id" => component_id).select(:"#{component_type}_id")

      components_with_dates.distinct.each do |component_with_dates|
        components = self[:"#{component_type}"].where(id: component_with_dates[:"#{component_type}_id"])
        # Save the old display string for later logging
        old_display_string = self[:"#{component_type}"].where(id: component_with_dates[:"#{component_type}_id"]).get(:display_string)
        components.each do |component|
          date_recs = self[:date].where("#{component_type}_id": component[:id])
          date_parts = []
          # Date logic used in archival object and digital object component model autogenerate proc
          date_recs.each do |date_rec|
            if date_rec[:expression] != nil
              date_parts << (date_rec[:date_type_id] == bulk_date ? "bulk: #{date_rec[:expression]}" : date_rec[:expression])
            elsif date_rec[:begin] && date_rec[:end]
              date_parts << (date_rec[:date_type_id] == bulk_date ? "bulk: #{date_rec[:begin]} - #{date_rec[:end]}" : "#{date_rec[:begin]} - #{date_rec[:end]}")
            else
              date_parts << (date_rec[:date_type_id] == bulk_date ? "bulk: #{date_rec[:begin]}" : date_rec[:begin])
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
