# Calculates the read-only `thumbnail` property shown for a record in the staff and public interfaces.
# The functions here are shared by the mixins that add the property to models:
#
#   * Thumbnails::FromFileVersions: Digital Objects and Digital Object Components
#   * Thumbnails::FromRepresentativeInstance: Accessions, Archival Objects and Resources
#   * Thumbnails::FromResourceTree: the Archival Object fallback of Resources
#
# A Digital Object's thumbnail comes from its own published File Versions:
#
#   * the File Version marked `is_display_thumbnail` supplies the image, whatever its file format; if
#     the browser cannot render it, the interfaces show a generic icon in its place
#   * the File Version marked `is_display_link` supplies the link; there is no fallback, so without
#     one the thumbnail or generic icon has no link
#   * with neither marked, there is no thumbnail
#   * caption: the thumbnail File Version's caption, else the link File Version's caption,
#     else the record's title (display string for a component)
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
        'link_url' => (link_fv['file_uri'] if link_fv),
        'caption' => [thumbnail_fv, link_fv].compact.map { |fv| fv['caption'] }.find { |caption| caption && !caption.strip.empty? } || title,
        'digital_object_type' => digital_object_type,
      }.compact
    end

    # Thumbnails of the published, unsuppressed Digital Objects with the given ids, keyed by id,
    # linking to the Digital Object record.
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

      digital_objects.each_with_object({}) do |digital_object, result|
        thumbnail = thumbnail_for_file_versions(
          file_versions.fetch(digital_object.id, []).map { |fv| file_version_hash(fv) },
          digital_object.title,
          BackendEnumSource.value_for_id('digital_object_digital_object_type', digital_object.digital_object_type_id)
        )
        next unless thumbnail

        thumbnail.delete('link_url')
        thumbnail['record_uri'] = JSONModel(:digital_object).uri_for(digital_object.id, :repo_id => digital_object.repo_id)
        result[digital_object.id] = thumbnail
      end
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
