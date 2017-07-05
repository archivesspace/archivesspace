module PrefixHelper

  def self.app_prefix(uri)
    AppConfig[:public_proxy_prefix].gsub(/\/?$/, '') + uri
  end

  def self.app_prefix_js
    prefix = AppConfig[:public_proxy_prefix].gsub(/\/?$/, '')

    "'#{prefix}' +"
  end

  def app_prefix(uri)
    PrefixHelper.app_prefix(uri)
  end

  def app_prefix_js
    PrefixHelper.app_prefix_js
  end

end
