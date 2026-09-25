# frozen_string_literal: true

# Helpers for public_proxy_prefix_spec only.
# With ASPACE_TEST_PUBLIC_PROXY_PREFIX=true, spec_helper sets public_url with
# a path segment so routes and app_prefix-generated links share the same prefix.
module PublicProxyPrefixFeatureHelpers
  # Strips trailing slash.
  def pui_proxy_path_prefix
    AppConfig[:public_proxy_prefix].gsub(%r{/+\z}, '')
  end

  # Like Capybara visit, but prepends the public proxy path when configured.
  def visit_prefixed(path = '/')
    path = path.start_with?('/') ? path : "/#{path}"
    base = pui_proxy_path_prefix
    visit(base.empty? ? path : "#{base}#{path}")
  end
end
