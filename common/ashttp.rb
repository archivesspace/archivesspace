# Small wrapper for common net/http functions.  Just to give us a central place to set parameters.
require 'net/http'

class ASHTTP

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

end
