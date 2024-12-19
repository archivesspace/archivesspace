# Be sure to restart your server when you modify this file.

# Use httponly because some of our AJAX handlers need access to the session too.
ArchivesSpace::Application.config.session_store :cookie_store,
  key: "#{AppConfig[:cookie_prefix]}_session",
  httponly: true,
  same_site: :lax

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# ArchivesSpace::Application.config.session_store :active_record_store
