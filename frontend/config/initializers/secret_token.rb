require 'digest/sha1'

if !ENV['DISABLE_STARTUP']
  ArchivesSpace::Application.config.secret_token = Digest::SHA1.hexdigest(AppConfig[:frontend_cookie_secret])
  ArchivesSpace::Application.config.secret_key_base = Digest::SHA1.hexdigest(AppConfig[:frontend_cookie_secret])
end
