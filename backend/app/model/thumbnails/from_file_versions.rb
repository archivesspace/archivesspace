# Adds the read-only `thumbnail` property to Digital Objects and Digital Object Components, from
# their own published File Versions.
module Thumbnails
  module FromFileVersions
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def sequel_to_jsonmodel(objs, opts = {})
        jsons = super

        titles_and_types = thumbnail_titles_and_types(jsons, objs)

        jsons.zip(objs).each do |json, obj|
          title, digital_object_type = titles_and_types.fetch(obj.id)
          json['thumbnail'] = Rules.thumbnail_for_file_versions(Array(json['file_versions']), title, digital_object_type)
        end

        jsons
      end

      private

      # { record id => [caption fallback, digital object type] }. A component falls back to its display
      # string and shows the type of its Digital Object.
      def thumbnail_titles_and_types(jsons, objs)
        if self == DigitalObjectComponent
          type_ids = DigitalObject.any_repo
                       .filter(:id => objs.map(&:root_record_id).uniq)
                       .select(:id, :digital_object_type_id)
                       .to_h { |row| [row[:id], row[:digital_object_type_id]] }

          jsons.zip(objs).to_h do |json, obj|
            [obj.id, [json['display_string'],
                      BackendEnumSource.value_for_id('digital_object_digital_object_type', type_ids[obj.root_record_id])]]
          end
        else
          jsons.zip(objs).to_h { |json, obj| [obj.id, [json['title'], json['digital_object_type']]] }
        end
      end
    end
  end
end
