# Be sure to restart your server when you modify this file.

Rails.application.config.session_store :cookie_store,
  key: "_archivesspace-public_session",
  httponly: true,
  same_site: :lax
