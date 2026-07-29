require 'cgi'

class IIIF
  IIIF_FILE_FORMAT_NAME = 'iiif'
  IIIF_USE_STATEMENT = 'text-json'
  IIIF_XLINK_SHOW_ATTRIBUTE = 'embed'

  # AppConfig[:iiif_viewer] value that disables the embedded viewer entirely.
  NONE = 'none'

  # The viewers ArchivesSpace bundles and serves from its own static dir, keyed
  # on the name used in AppConfig[:iiif_viewer].
  BUNDLED_VIEWER_PATHS = {
    'universal_viewer' => 'uv/uv.html#?manifest=',
    'mirador' => 'mirador/index.html?manifest=',
  }.freeze

  # Returns the viewer URL for a manifest, from AppConfig[:iiif_viewer] resolved
  # for the given repository (see resolve_viewer). The resolved value may be:
  #   - 'universal_viewer' or 'mirador': a bundled viewer served from the app's
  #     own static dir. `app_prefix` is the app's URL path prefix, e.g.
  #     AppConfig[:frontend_proxy_prefix] / AppConfig[:public_proxy_prefix].
  #   - a URL String: an externally hosted viewer, with the escaped manifest URI
  #     appended.
  #   - a Proc: called with the manifest URI, returning the full viewer URL.
  def self.viewer_url(current_repo_code, manifest_uri, app_prefix = nil)
    viewer = resolve_viewer(current_repo_code)

    if viewer.is_a?(Proc)
      viewer.call(manifest_uri)
    elsif BUNDLED_VIEWER_PATHS.has_key?(viewer) && app_prefix
      "#{app_prefix}#{BUNDLED_VIEWER_PATHS[viewer]}#{CGI::escape(manifest_uri)}"
    elsif external_viewer_url?(viewer)
      viewer + CGI::escape(manifest_uri)
    else
      raise 'IIIF viewer URL configuration must be a String or a Proc'
    end
  end

  # Whether a viewer is available for the given repository (nil resolves the
  # default). False when the resolved value is 'none' or unset.
  def self.enabled?(current_repo_code = nil)
    viewer = resolve_viewer(current_repo_code)

    viewer.is_a?(Proc) || (viewer.is_a?(String) && viewer != NONE)
  end

  # Resolves AppConfig[:iiif_viewer] for the given repository. When the config is
  # a Hash it is keyed on repo_code with a :default fallback; otherwise the value
  # applies to all repositories. Returns nil when unset.
  def self.resolve_viewer(current_repo_code)
    return nil unless AppConfig.has_key?(:iiif_viewer)

    config = AppConfig[:iiif_viewer]
    config.is_a?(Hash) ? config.fetch(current_repo_code, config[:default]) : config
  end

  # Whether the resolved value is an externally hosted viewer URL: any String
  # that is not 'none' or the name of a bundled viewer.
  def self.external_viewer_url?(viewer)
    viewer.is_a?(String) && viewer != NONE && !BUNDLED_VIEWER_PATHS.has_key?(viewer)
  end

  def self.manifest?(file_version)
    file_version['file_format_name'] == IIIF_FILE_FORMAT_NAME &&
      file_version['use_statement'] == IIIF_USE_STATEMENT &&
      file_version['xlink_show_attribute'] == IIIF_XLINK_SHOW_ATTRIBUTE
  end
end
