require 'ipaddr'

# Limits failed logins in the staff interface and the PUI with Rack::Attack::Fail2Ban.
# Settings are read from AppConfig with the given prefix (:frontend or :pui).
# nil, false, 0 or text in a setting turns that limit off.
#
# Three limits apply to a login attempt:
#  - failed logins for one username from one client IP
#  - failed logins from one client IP, for any username
#  - failed logins for one username, from any IP (a higher backstop, over a longer period)
#
# The first limit is per IP so that an attacker guessing one user's password from
# their own IP blocks only themselves, not the real user.
class LoginThrottle

  # The reverse proxies allowed to set X-Forwarded-For, from AppConfig[:trusted_proxies],
  # or nil to keep the Rails default (loopback and private ranges).
  def self.trusted_proxies
    addresses = Array(AppConfig[:trusted_proxies])
                .flat_map { |value| value.to_s.split(',') }
                .map(&:strip)
                .reject(&:empty?)

    addresses.empty? ? nil : addresses.map { |address| IPAddr.new(address) }
  end


  # Logged once per process, so a misconfigured proxy doesn't fill the log.
  def self.warn_client_ip_unknown(client_ip)
    return if @warned_client_ip_unknown

    @warned_client_ip_unknown = true
    Rails.logger.warn("Login throttling: logins come from the proxy address #{client_ip} with no X-Forwarded-For header, " \
                      "so failed logins can't be counted per client IP. Configure the proxy to send X-Forwarded-For.")
  end


  def initialize(prefix, username, request)
    @prefix = prefix
    @username = username.to_s.strip.downcase
    @client_ip = request.remote_ip
  end


  def throttled?
    limits.keys.any? { |key| Rack::Attack::Fail2Ban.banned?(key) }
  end


  def record_failure
    limits.each do |key, (limit, period)|
      Rack::Attack::Fail2Ban.filter(key, maxretry: limit, findtime: period, bantime: period) { true }
    end
  end


  # Reset only the username counts. If a successful login reset the IP count, an attacker
  # with any valid account could log in to it between guesses and never reach the IP limit.
  def reset
    limits.slice(username_ip_key, username_key).each do |key, (_limit, period)|
      Rack::Attack::Fail2Ban.reset(key, findtime: period)
    end
  end


  private

  def setting(name)
    AppConfig[:"#{@prefix}_login_#{name}"].to_s.to_i
  end


  # Each Fail2Ban key with its failure limit and period, for the limits that are on.
  def limits
    period = setting(:throttle_period)
    backstop_period = setting(:username_backstop_period)

    limits = {}
    if period > 0 && client_ip_known?
      limits[username_ip_key] = [setting(:throttle_limit), period]
      limits[ip_key] = [setting(:ip_throttle_limit), period]
    end
    limits[username_key] = [setting(:username_backstop_limit), backstop_period] if backstop_period > 0

    limits.select { |_key, (limit, _period)| limit > 0 }
  end


  # The IP goes first: an IP never contains '/', so no username can make two keys collide.
  def username_ip_key
    "#{@prefix}_login_username_ip:#{@client_ip}/#{@username}"
  end


  def ip_key
    "#{@prefix}_login_ip:#{@client_ip}"
  end


  def username_key
    "#{@prefix}_login_username:#{@username}"
  end


  # When the client IP is a proxy's own address, the proxy did not send X-Forwarded-For,
  # so every client shares that address. Counting by it would let anyone's failed logins
  # block logins for everyone, so the per IP limits are skipped and only the
  # username backstop applies.
  def client_ip_known?
    address = IPAddr.new(@client_ip)
    proxies = self.class.trusted_proxies
    from_proxy = proxies ? proxies.any? { |range| range.include?(address) } : address.loopback?
    return true unless from_proxy

    self.class.warn_client_ip_unknown(@client_ip)
    false
  rescue IPAddr::Error
    true
  end
end
