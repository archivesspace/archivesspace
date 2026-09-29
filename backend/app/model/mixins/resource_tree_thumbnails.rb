# For Resources, after RepresentativeInstanceThumbnails: a Resource whose own representative instance
# shows no image also considers the representative instances of its published, unsuppressed Archival
# Objects, in tree order.
module ResourceTreeThumbnails
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    private

    def representative_thumbnail_candidates(resource_ids)
      candidates = super

      # Only walk the trees of Resources whose own representative instance does not show an image
      own_thumbnails = Thumbnails.digital_object_thumbnails(candidates.values.flatten.uniq)
      needs_tree = resource_ids.reject { |id|
        candidates.fetch(id, []).any? { |do_id| own_thumbnails.dig(do_id, 'image_url') }
      }

      tree_representative_digital_object_ids(needs_tree).each do |resource_id, do_ids|
        candidates[resource_id] = candidates.fetch(resource_id, []) + do_ids
      end

      candidates
    end

    # { resource id => [digital object id, ...] } for the representative instances of published,
    # unsuppressed Archival Objects, in tree order
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
                       Sequel.qualify(:archival_object, :root_record_id),
                       Sequel.qualify(:instance_do_link_rlshp, :digital_object_id))
               .all

      paths = tree_paths(rows.map { |row| row[:id] })

      rows
        .sort_by { |row| paths.fetch(row[:id]) }
        .each_with_object({}) { |row, result| (result[row[:root_record_id]] ||= []) << row[:digital_object_id] }
    end

    # { archival object id => [position of the top-level ancestor, ..., own position] }, so that sorting
    # by the path gives tree (depth-first) order. Walks up one level per query.
    def tree_paths(archival_object_ids)
      paths = archival_object_ids.to_h { |id| [id, []] }
      current = archival_object_ids.to_h { |id| [id, id] }

      until current.empty?
        nodes = ArchivalObject.any_repo
                  .filter(:id => current.values.uniq)
                  .select(:id, :parent_id, :position)
                  .to_h { |row| [row[:id], row] }

        current = current.each_with_object({}) do |(id, node_id), next_level|
          node = nodes.fetch(node_id)
          paths[id].unshift(node[:position])
          next_level[id] = node[:parent_id] if node[:parent_id]
        end
      end

      paths
    end
  end
end
