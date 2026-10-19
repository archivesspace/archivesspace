# Adds the read-only `thumbnail` property to Accessions, Archival Objects and Resources: the thumbnail
# of the Digital Object linked by their instance marked `is_representative`, linking to that Digital
# Object record. When several candidate Digital Objects show a thumbnail, the first image wins,
# otherwise the first generic icon.
module Thumbnails
  module FromRepresentativeInstance
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def sequel_to_jsonmodel(objs, opts = {})
        jsons = super

        candidates = representative_thumbnail_candidates(objs.map(&:id))
        thumbnails = Rules.digital_object_thumbnails(candidates.values.flatten.uniq)

        jsons.zip(objs).each do |json, obj|
          found = candidates.fetch(obj.id, []).map { |do_id| thumbnails[do_id] }.compact
          json['thumbnail'] = found.find { |thumbnail| thumbnail['image_url'] } || found.first
        end

        jsons
      end

      private

      # { record id => [digital object id, ...] }: the Digital Objects to take the thumbnail from, in
      # order of preference. Here, those linked by the record's representative instance.
      def representative_thumbnail_candidates(record_ids)
        fk_column = :"#{table_name}_id"

        Instance
          .join(:instance_do_link_rlshp, Sequel.qualify(:instance_do_link_rlshp, :instance_id) => Sequel.qualify(:instance, :id))
          .filter(Sequel.qualify(:instance, fk_column) => record_ids)
          .filter(Sequel.qualify(:instance, :is_representative) => 1)
          .select(Sequel.qualify(:instance, fk_column), Sequel.qualify(:instance_do_link_rlshp, :digital_object_id))
          .each_with_object({}) { |row, result| (result[row[fk_column]] ||= []) << row[:digital_object_id] }
      end
    end
  end
end
