# The file URI of a file version is free text, so it can hold a scheme such as javascript: that runs
# a script when followed. Ask here before linking to one, e.g. thumbnail links, file version lists.

module FileURI
  # data: is allowed (ANW-1719)
  ALLOWED_SCHEMES = %w[http https data].freeze

  # Whether the file_uri is allowed to be the href of a link. A uri with no scheme or anything unusual
  # before the first colon is not allowed.
  def self.allowed_scheme?(file_uri)
    ALLOWED_SCHEMES.include?(scheme(file_uri))
  end

  # Browsers block links opening a data: uri in a new window, but let them download it
  def self.download_only?(file_uri)
    scheme(file_uri) == 'data'
  end

  def self.scheme(file_uri)
    file_uri.to_s.strip[/\A([a-z][a-z0-9+.\-]*):/i, 1]&.downcase
  end
  private_class_method :scheme
end
