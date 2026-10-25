# For Resources, after FromRepresentativeInstance: a Resource whose own representative instance
# shows no image also considers the representative instances of its published, unsuppressed Archival
# Objects, in tree order.
module Thumbnails
  module FromResourceTree
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      private

      def representative_thumbnail_candidates(resource_ids)
        candidates = super

        # Only walk the trees of Resources whose own representative instance does not show an image
        own_thumbnails = Rules.digital_object_thumbnails(candidates.values.flatten.uniq)
        needs_tree = resource_ids.reject { |id|
          candidates.fetch(id, []).any? { |do_id| own_thumbnails.dig(do_id, 'image_url') }
        }

        tree_representative_digital_object_ids(needs_tree).each do |resource_id, do_ids|
          candidates[resource_id] = candidates.fetch(resource_id, []) + do_ids
        end

        candidates
      end

      # { resource id => [digital object id, ...] } for the representative instances of published,
      # unsuppressed Archival Objects without an unpublished or suppressed ancestor, in tree order
      def tree_representative_digital_object_ids(resource_ids)
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

        hidden = Rules.with_hidden_ancestor(ArchivalObject, rows.to_h { |row| [row[:id], row[:parent_id]] })
        rows = rows.reject { |row| hidden.include?(row[:id]) }

        paths = Rules.tree_paths(ArchivalObject, rows.map { |row| row[:id] })

        rows
          .sort_by { |row| paths.fetch(row[:id]) }
          .each_with_object({}) { |row, result| (result[row[:root_record_id]] ||= []) << row[:digital_object_id] }
      end
    end
  end
end
