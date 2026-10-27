# For Resources, after FromRepresentativeInstance: after its own representative instance, a Resource
# considers the representative instances of its published, unsuppressed Archival Objects, in tree order.
module Thumbnails
  module FromResourceTree
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      private

      def representative_thumbnail_candidates(resource_ids)
        candidates = super

        # The own image may fail to load in the browser, so the tree supplies the fallbacks
        tree_representative_digital_object_ids(resource_ids, candidates).each do |resource_id, do_ids|
          candidates[resource_id] = candidates.fetch(resource_id, []) + do_ids
        end

        candidates
      end

      # { resource id => [digital object id, ...] } for the representative instances of published,
      # unsuppressed Archival Objects without an unpublished or suppressed ancestor, in tree order.
      # A tree can be large, so only the Archival Objects whose Digital Object can show an image are put in
      # order, and only the first Rules.max_images of those are kept. Only when none can, and the Resource
      # has no representative instance of its own with a thumbnail, are the others put in order, for the
      # first generic icon.
      def tree_representative_digital_object_ids(resource_ids, own_candidates)
        return {} if resource_ids.empty?

        rows = ArchivalObject.any_repo
                 .join(:instance, Sequel.qualify(:instance, :archival_object_id) => Sequel.qualify(:archival_object, :id))
                 .join(:instance_do_link_rlshp, Sequel.qualify(:instance_do_link_rlshp, :instance_id) => Sequel.qualify(:instance, :id))
                 .filter(Sequel.qualify(:archival_object, :root_record_id) => resource_ids)
                 .filter(Sequel.qualify(:archival_object, :publish) => 1)
                 .filter(Sequel.qualify(:archival_object, :suppressed) => 0)
                 .filter(Sequel.qualify(:instance, :is_representative) => 1)
                 .select(Sequel.qualify(:archival_object, :id),
                         Sequel.qualify(:archival_object, :parent_id),
                         Sequel.qualify(:archival_object, :root_record_id),
                         Sequel.qualify(:instance_do_link_rlshp, :digital_object_id))
                 .all

        with_image = Rules.digital_objects_with_image(rows.map { |row| row[:digital_object_id] }.uniq).to_h { |id| [id, true] }
        image_rows, icon_rows = rows.partition { |row| with_image[row[:digital_object_id]] }

        max_images = Rules.max_images
        result = in_tree_order(image_rows).transform_values { |do_ids| do_ids.uniq.first(max_images) }

        own_thumbnails = Rules.digital_object_thumbnails(own_candidates.values.flatten.uniq)
        without_candidates = resource_ids.reject { |id|
          result.key?(id) || own_candidates.fetch(id, []).any? { |do_id| own_thumbnails.key?(do_id) }
        }
        icon_rows = icon_rows.select { |row| without_candidates.include?(row[:root_record_id]) }
        result.merge(in_tree_order(icon_rows).transform_values { |do_ids| do_ids.first(1) })
      end

      # { resource id => [digital object id, ...] } from the rows, in tree order, without the rows of
      # Archival Objects with an unpublished or suppressed ancestor
      def in_tree_order(rows)
        hidden = Rules.with_hidden_ancestor(ArchivalObject, rows.to_h { |row| [row[:id], row[:parent_id]] })
        rows = rows.reject { |row| hidden.include?(row[:id]) }

        paths = Rules.tree_paths(ArchivalObject, rows.map { |row| row[:id] }.uniq)

        rows
          .sort_by { |row| paths.fetch(row[:id]) }
          .each_with_object({}) { |row, result| (result[row[:root_record_id]] ||= []) << row[:digital_object_id] }
      end
    end
  end
end
