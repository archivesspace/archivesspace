# Failed staff logins per username and per client IP are limited in
# SessionController#login with Rack::Attack::Fail2Ban. Counts are kept in memory.
Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
