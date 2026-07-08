require 'cgi'

class IIIF
  IIIF_FILE_FORMAT_NAME = 'iiif'
  IIIF_USE_STATEMENT = 'text-json'
  IIIF_XLINK_SHOW_ATTRIBUTE = 'embed'
  BUNDLED_VIEWER_PATH = 'uv/uv.html'

  # Returns the viewer URL for a manifest. A repository-specific or :default
  # AppConfig[:iiif_viewer_url] entry takes precedence. Otherwise the bundled
  # Universal Viewer is used (when enabled and an app_prefix is supplied).
  # `app_prefix` is the app's URL path prefix, e.g.
  # AppConfig[:frontend_proxy_prefix] / AppConfig[:public_proxy_prefix].
  def self.viewer_url(current_repo_code, manifest_uri, app_prefix = nil)
    viewer_url_config = external_viewer_config(current_repo_code)

    if viewer_url_config.is_a?(String)
      viewer_url_config + CGI::escape(manifest_uri)
    elsif viewer_url_config.is_a?(Proc)
      viewer_url_config.call(manifest_uri)
    elsif bundled_viewer_enabled? && app_prefix
      "#{app_prefix}#{BUNDLED_VIEWER_PATH}#?manifest=#{CGI::escape(manifest_uri)}"
    else
      raise 'IIIF viewer URL configuration must be a String or a Proc'
    end
  end

  def self.enabled?
    bundled_viewer_enabled? || external_default_configured?
  end

  def self.bundled_viewer_enabled?
    AppConfig.has_key?(:iiif_use_bundled_viewer) && AppConfig[:iiif_use_bundled_viewer]
  end

  # Returns the configured external viewer (String or Proc) for the given repo,
  # falling back to the :default entry, or nil when nothing external is set.
  def self.external_viewer_config(current_repo_code)
    return nil unless AppConfig.has_key?(:iiif_viewer_url) && AppConfig[:iiif_viewer_url].is_a?(Hash)

    config = AppConfig[:iiif_viewer_url]
    config.fetch(current_repo_code, config[:default])
  end

  def self.external_default_configured?
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
