require 'ashttp'

# Fire a HTTP request with retry logic for flakey REST APIs.
class HTTPRequest

  OPEN_TIMEOUT = 5
  READ_TIMEOUT = 5

  RETRIES = 10

  def get(uri)
    RETRIES.times do |retry_count|
      if retry_count > 0
        Rails.logger.warn("Retrying GET for #{uri} (attempt #{retry_count} of #{RETRIES})")
      end

      begin
        ASHTTP.start_uri(uri, :open_timeout => OPEN_TIMEOUT, :read_timeout => READ_TIMEOUT) do |http|
          request = Net::HTTP::Get.new(uri)
          response = http.request(request)

          return yield response
        end
      rescue Timeout::Error => e
        Rails.logger.warn("Timeout on request: " + e.to_s)
      end
    end
  end

end
