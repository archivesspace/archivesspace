require 'cgi'

class IIIF
  IIIF_FILE_FORMAT_NAME = 'iiif'
  IIIF_USE_STATEMENT = 'text-json'
  IIIF_XLINK_SHOW_ATTRIBUTE = 'embed'

  def self.viewer_url(current_repo_code, manifest_uri)
    viewer_url_config = AppConfig[:iiif_viewer_url].fetch(current_repo_code, AppConfig[:iiif_viewer_url].fetch(:default))

    if viewer_url_config.is_a?(String)
      viewer_url_config + CGI::escape(manifest_uri)
    elsif viewer_url_config.is_a?(Proc)
      viewer_url_config.call(manifest_uri)
    else
      raise 'IIIF viewer URL configuration must be a String or a Proc'
    end
  end

  def self.enabled?
    AppConfig.has_key?(:iiif_viewer_url) &&
      AppConfig[:iiif_viewer_url].is_a?(Hash) &&
      AppConfig[:iiif_viewer_url].has_key?(:default)
  end

  def self.manifest?(file_version)
    file_version['file_format_name'] == IIIF_FILE_FORMAT_NAME &&
      file_version['use_statement'] == IIIF_USE_STATEMENT &&
      file_version['xlink_show_attribute'] == IIIF_XLINK_SHOW_ATTRIBUTE
  end
end
