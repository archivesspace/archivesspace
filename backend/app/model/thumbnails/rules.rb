require 'file_uri'

# Calculates the read-only `thumbnail` property shown in the staff and public interfaces, for the
# mixins that add it:
#   * FromFileVersions: Digital Objects and Components, from their own File Versions
#   * FromRepresentativeInstance: Accessions, Archival Objects and Resources, from the Digital Object
#     of their representative instance, linking to its record
#   * FromResourceTree: Resources whose own representative instance shows no image, from those of
#     their Archival Objects in tree order
#
# From the published File Versions, if one is marked:
#   * image: the `is_display_thumbnail` one, in any format. If the browser cannot render it, the
#     interfaces show a generic icon, linked to the image file when there is no other link (ANW-3001).
#   * link: the `is_display_link` one, if its scheme is allowed
#   * caption: the image's, else the link's, else the record title (a Component's display string)
#
# A representative Digital Object without an image takes that of its first Component with one (tree
# order; published, unsuppressed, no unpublished or suppressed ancestor), linking to it (ANW-3057).
module Thumbnails
  module Rules
    # file_versions: hashes with the file_version JSONModel property names
    def self.thumbnail_for_file_versions(file_versions, title, digital_object_type)
      published = file_versions.select { |fv| fv['publish'] }
      thumbnail_fv = published.find { |fv| fv['is_display_thumbnail'] }
      link_fv = published.find { |fv| fv['is_display_link'] }

      return nil unless thumbnail_fv || link_fv

      {
        'image_url' => (thumbnail_fv['file_uri'] if thumbnail_fv),
        'link_url' => (link_fv['file_uri'] if link_fv && FileURI.allowed_scheme?(link_fv['file_uri'])),
        'caption' => [thumbnail_fv, link_fv].compact.map { |fv| fv['caption'] }.find { |caption| caption && !caption.strip.empty? } || title,
        'digital_object_type' => digital_object_type,
      }.compact
    end

    # Thumbnails of the published, unsuppressed Digital Objects with the given ids, keyed by id,
    # linking to the Digital Object record, or to the Digital Object Component whose image is shown.
    def self.digital_object_thumbnails(digital_object_ids)
      return {} if digital_object_ids.empty?

      digital_objects = DigitalObject.any_repo
                          .filter(:id => digital_object_ids, :publish => 1, :suppressed => 0)
                          .select(:id, :repo_id, :title, :digital_object_type_id)
                          .all

      file_versions = FileVersion
                        .filter(:digital_object_id => digital_objects.map(&:id), :publish => 1)
                        .order(:id)
                        .all
                        .group_by(&:digital_object_id)

      types = digital_objects.to_h { |digital_object|
        [digital_object.id, BackendEnumSource.value_for_id('digital_object_digital_object_type', digital_object.digital_object_type_id)]
      }

      thumbnails = digital_objects.each_with_object({}) do |digital_object, result|
        thumbnail = thumbnail_for_file_versions(
          file_versions.fetch(digital_object.id, []).map { |fv| file_version_hash(fv) },
          digital_object.title,
          types.fetch(digital_object.id)
        )
        next unless thumbnail

        thumbnail.delete('link_url')
        thumbnail['record_uri'] = JSONModel(:digital_object).uri_for(digital_object.id, :repo_id => digital_object.repo_id)
        result[digital_object.id] = thumbnail
      end

      without_image = digital_objects.map(&:id).reject { |id| thumbnails.dig(id, 'image_url') }
      thumbnails.merge(component_image_thumbnails(without_image, types))
    end

    # { digital object id => thumbnail } of the first published, unsuppressed Digital Object Component
    # without an unpublished or suppressed ancestor (in tree order) of each Digital Object that has a
    # published Display Thumbnail File Version, linking to that component. types: { digital object id => digital object type }
    def self.component_image_thumbnails(digital_object_ids, types)
      return {} if digital_object_ids.empty?

      components = DigitalObjectComponent.any_repo
                     .filter(:root_record_id => digital_object_ids, :publish => 1, :suppressed => 0)
                     .select(:id, :repo_id, :root_record_id, :parent_id, :display_string)
                     .all

      hidden = with_hidden_ancestor(DigitalObjectComponent, components.to_h { |component| [component.id, component.parent_id] })
      components = components.reject { |component| hidden.include?(component.id) }

      file_versions = FileVersion
                        .filter(:digital_object_component_id => components.map(&:id), :publish => 1)
                        .order(:id)
                        .all
                        .group_by(&:digital_object_component_id)

      with_image = components.select { |component|
        file_versions.fetch(component.id, []).any? { |fv| fv.is_display_thumbnail == 1 }
      }
      paths = tree_paths(DigitalObjectComponent, with_image.map(&:id))

      with_image.group_by(&:root_record_id).transform_values do |candidates|
        component = candidates.min_by { |candidate| paths.fetch(candidate.id) }
        thumbnail = thumbnail_for_file_versions(
          file_versions.fetch(component.id).map { |fv| file_version_hash(fv) },
          component.display_string,
          types.fetch(component.root_record_id)
        )
        thumbnail.delete('link_url')
        thumbnail['record_uri'] = JSONModel(:digital_object_component).uri_for(component.id, :repo_id => component.repo_id)
        thumbnail
      end
    end

    # { node id => [position of the top-level ancestor, ..., own position] } for nodes of a tree model
    # (Archival Objects, Digital Object Components), so that sorting by the path gives tree
    # (depth-first) order. Walks up one level per query.
    def self.tree_paths(model, ids)
      paths = ids.to_h { |id| [id, []] }
      current = ids.to_h { |id| [id, id] }

      until current.empty?
        nodes = model.any_repo
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

    # The ids of the nodes of a tree model (Archival Objects, Digital Object Components) with an
    # unpublished or suppressed ancestor, from { node id => parent id }. Walks up one level per query.
    def self.with_hidden_ancestor(model, parent_ids)
      hidden = []
      current = parent_ids.compact

      until current.empty?
        ancestors = model.any_repo
                      .filter(:id => current.values.uniq)
                      .select(:id, :parent_id, :publish, :suppressed)
                      .to_h { |row| [row[:id], row] }

        current = current.each_with_object({}) do |(id, ancestor_id), next_level|
          # A suppressed ancestor is missing when the request enforces suppression
          ancestor = ancestors[ancestor_id]

          if ancestor.nil? || ancestor[:publish] != 1 || ancestor[:suppressed] == 1
            hidden << id
          elsif ancestor[:parent_id]
            next_level[id] = ancestor[:parent_id]
          end
        end
      end

      hidden
    end

    def self.file_version_hash(file_version)
      {
        'file_uri' => file_version.file_uri,
        'publish' => file_version.publish == 1,
        'caption' => file_version.caption,
        'is_display_thumbnail' => file_version.is_display_thumbnail == 1,
        'is_display_link' => file_version.is_display_link == 1,
      }
    end
  end
end
