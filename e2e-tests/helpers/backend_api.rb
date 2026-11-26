# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

# Minimal client for the ArchivesSpace backend REST API, for scenario setup and
# teardown that would be slow or awkward to do through the UI (for example
# adding dozens of controlled values). Scenarios themselves should still
# exercise the app through the browser.
module BackendApi
  class Error < StandardError; end

  module_function

  def get(path)
    request(Net::HTTP::Get, path)
  end

  def post(path, body = nil)
    request(Net::HTTP::Post, path, body)
  end

  def session
    @session ||= begin
      response = login_request
      raise Error, "Backend login failed (#{response.code}): #{response.body}" unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body).fetch('session')
    end
  end

  def login_request
    uri = URI("#{BACKEND_URL}/users/admin/login")
    req = Net::HTTP::Post.new(uri)
    req.set_form_data(password: 'admin')

    Net::HTTP.start(uri.host, uri.port) { |http| http.request(req) }
  end

  def request(klass, path, body = nil)
    response = http_request(klass, path, body, session)

    if response.code.to_i == 412 # session expired
      @session = nil
      response = http_request(klass, path, body, session)
    end

    raise Error, "#{klass::METHOD} #{path} failed (#{response.code}): #{response.body}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  end

  def http_request(klass, path, body = nil, token = nil)
    uri = URI("#{BACKEND_URL}#{path}")

    req = klass.new(uri)
    req['X-ArchivesSpace-Session'] = token if token

    if body
      req['Content-Type'] = 'application/json'
      req.body = JSON.generate(body)
    end

    Net::HTTP.start(uri.host, uri.port) { |http| http.request(req) }
  end
end

def enumeration_named(enum_name)
  BackendApi.get("/config/enumerations/names/#{enum_name}")
end

def add_enumeration_values(enum_name, values)
  enumeration = enumeration_named(enum_name)
  enumeration['values'] |= values

  BackendApi.post(enumeration['uri'], enumeration)
end

def remove_enumeration_values(enum_name, values)
  enumeration = enumeration_named(enum_name)
  enumeration['values'] -= values

  BackendApi.post(enumeration['uri'], enumeration)
end
