# Small wrapper for common net/http functions.  Just to give us a central place to set parameters.
require 'net/http'
require 'tempfile'
require 'uri'
require 'asconstants'

class ASHTTP

  PLACEHOLDER_HOSTS = ['localhost', '127.0.0.1', '0.0.0.0', '::1', 'example.com', 'example.org', 'example.net'].freeze
  MAX_REDIRECTS = 5

  def self.start_uri(uri, opts = {})
    use_ssl = (uri.scheme == "https")
    opts = {:use_ssl => use_ssl}.merge(opts)

    Net::HTTP.start(uri.host, uri.port, opts) do |http|
      yield http
    end
  end

  def self.get(*args)
    Net::HTTP.get(*args)
  end

  def self.get_response(*args)
    Net::HTTP.get_response(*args)
  end

  def self.post_form(*args)
    Net::HTTP.post_form(*args)
  end

  # ANW-3136: Java's default "Java/<version>" User-Agent is rejected by some image
  # hosts, so the PDF renderers can't fetch logos from them. Identify ourselves
  # with the first usable URL: the repository contact_url, the public URL from
  # the AppConfig, or nil.
  def self.user_agent(contact_url = nil)
    product = "ArchivesSpace/#{ASConstants.VERSION.to_s.gsub(/\s+/, '-')}"
    contact = [contact_url, AppConfig[:public_proxy_url]].map { |url| usable_contact_url(url) }.compact.first

    contact ? "#{product} (+#{contact})" : product
  end

  def self.usable_contact_url(url)
    uri = URI.parse(url.to_s.strip)
    return nil unless uri.is_a?(URI::HTTP) && uri.hostname

    host = uri.hostname.downcase
    return nil unless host.include?('.') # single-word hosts, e.g. Docker's http://pui:8081
    return nil if PLACEHOLDER_HOSTS.any? { |placeholder| host == placeholder || host.end_with?(".#{placeholder}") }

    uri.to_s
  rescue URI::InvalidURIError
    nil
  end

  def self.download_image(url, contact_url: nil)
    uri = URI.parse(url.to_s.strip)
    return nil unless uri.is_a?(URI::HTTP) && uri.host

    body = fetch_image(uri, { 'User-Agent' => user_agent(contact_url), 'Accept' => 'image/*' }, MAX_REDIRECTS)
    file = Tempfile.new('pdf_image')
    file.binmode
    file.write(body)
    file.close
    file
  rescue StandardError => e
    message = "Unable to download image #{url} for PDF: #{e.class}: #{e.message}"
    defined?(Log) ? Log.warn(message) : warn(message)
    nil
  end

  def self.fetch_image(uri, headers, redirects_left)
    response = start_uri(uri, open_timeout: 10, read_timeout: 10) do |http|
      http.request(Net::HTTP::Get.new(uri, headers))
    end

    case response
    when Net::HTTPSuccess
      response.body
    when Net::HTTPRedirection
      raise 'too many redirects' if redirects_left.zero?

      target = URI.join(uri.to_s, response['location'].to_s)
      raise "redirect to non-http URL #{target}" unless target.is_a?(URI::HTTP)

      fetch_image(target, headers, redirects_left - 1)
    else
      raise "HTTP #{response.code}"
    end
  end

end
