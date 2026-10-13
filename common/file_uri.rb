# The file URI of a file version is free text, so it can hold any scheme, including ones such as
# javascript: that run script when followed. Every place that turns a file URI into a link asks here
# first: the backend thumbnail rules, the thumbnails in both interfaces, and the public File
# Versions list.
module FileURI
  # data: is allowed (ANW-1719)
  ALLOWED_SCHEMES = %w[http https data].freeze

  # Whether the file_uri is allowed to be the href of a link. A uri with no scheme or anything unusual
  # before the first colon is not allowed.
  def self.allowed_scheme?(file_uri)
    scheme = file_uri.to_s.strip[/\A([a-z][a-z0-9+.\-]*):/i, 1]
    !scheme.nil? && ALLOWED_SCHEMES.include?(scheme.downcase)
  end
end
