require 'ashttp'
require 'net/http/persistent'
require 'net/http/post/multipart'
require 'json'
require_relative 'exceptions'


module JSONModel

  # Set the repository that subsequent operations will apply to.
  def self.set_repository(id)
    Thread.current[:selected_repo_id] = id
  end


  # The currently selected repository (if any)
  def self.repository
    Thread.current[:selected_repo_id]
  end


  # Grab an array of JSON objects from 'uri' and use the 'type_descriptor'
  # property of each object to cast it into a JSONModel.
  def self.all(uri, type_descriptor)
    JSONModel::HTTP.get_json(uri).map do |obj|
      JSONModel(obj[type_descriptor.to_s]).new(obj)
    end
  end


  def self.with_repository(id)
    old_repo = Thread.current[:selected_repo_id]
    begin
      self.set_repository(id)
      yield
    ensure
      self.set_repository(old_repo)
    end
  end


  def self.backend_url
    if Module.const_defined?(:BACKEND_SERVICE_URL)
      BACKEND_SERVICE_URL
    else
      init_args[:url]
    end
  end


  @@error_handlers = []

  def self.add_error_handler(&block)
    @@error_handlers << block
  end

  def self.handle_error(err)
    @@error_handlers.each do |handler|
      handler.call(err)
    end
  end


  module Notification
    @@notification_handlers = []

    def self.add_notification_handler(code = nil, &block)
      @@notification_handlers << {:code => code, :block => block}
    end

    def self.start_background_thread
      Thread.new do
        sequence = 0

        while true
          begin
            notifications = JSONModel::HTTP::get_json('/notifications',
                                                      :last_sequence => sequence)

            notifications.each do |notification|
              @@notification_handlers.each do |handler|
                if handler[:code].nil? or handler[:code] == notification["code"]
                  begin
                    handler[:block].call(notification["code"], notification["params"])
                  rescue
                    $stderr.puts("ERROR: Failed to handle notification #{notification.inspect}: #{$!}")
                  end
                end
              end
            end

            sequence = notifications.last['sequence']
          rescue
            sleep 5
          end
        end
      end
    end

  end



  module HTTP

    def self.backend_url
      if Module.const_defined?(:BACKEND_SERVICE_URL)
        BACKEND_SERVICE_URL
      else
        JSONModel::init_args[:url]
      end
    end


    # We override this in the backend's spec_helper since Rack::Test::Methods
    # doesn't support multipart requests.
    def self.multipart_request(uri, params)
      Net::HTTP::Post::Multipart.new(uri, params)
    end


    def self.form_urlencoded(uri, params)
      request = Net::HTTP::Post.new(uri)
      request.form_data = params
      request
    end


    # Perform a HTTP POST request against the backend with form parameters
    #
    # `encoding' is either :x_www_form_urlencoded or :multipart_form_data.  The
    # latter is useful if you're providing a file upload.
    def self.post_form(uri, params = {}, encoding = :x_www_form_urlencoded)
      url = URI("#{backend_url}#{uri}")

      req = if encoding == :x_www_form_urlencoded
              self.form_urlencoded(url.request_uri, params)
            elsif encoding == :multipart_form_data
              self.multipart_request(url.request_uri, params)
            else
              raise "Unknown form encoding: #{encoding.inspect}"
            end

      do_http_request(url, req)
    end


    def self.stream(uri, params = {}, &block)
      uri = URI("#{backend_url}#{uri}")
      uri.query = URI.encode_www_form(params)

      req = Net::HTTP::Get.new(uri.request_uri)

      req['X-ArchivesSpace-Session'] = current_backend_session

      if high_priority?
        req['X-ArchivesSpace-Priority'] = "high"
      end

      ASHTTP.start_uri(uri) do |http|
        http.request(req, nil) do |response|
          if response.code =~ /^4/
            JSONModel::handle_error(ASUtils.json_parse(response.body))
            raise response.body
          end

          block.call(response)
        end
      end
    end


    def self.get_json(uri, params = {})
      if params.respond_to?(:to_unsafe_hash)
        params = params.to_unsafe_hash
      end

      uri = URI("#{backend_url}#{uri}")
      uri.query = URI.encode_www_form(params)

      response = get_response(uri)

      if response.is_a?(Net::HTTPSuccess) || response.code == '200'
        ASUtils.json_parse(response.body)
      else
        nil
      end
    end


    # Returns the session token to be sent to the backend when making
    # requests.
    def self.current_backend_session
      # Set by the ApplicationController
      Thread.current[:backend_session]
    end


    def self.current_backend_session=(val)
      Thread.current[:backend_session] = val
    end


    def self.high_priority?
      if Thread.current[:request_priority]
        Thread.current[:request_priority] == :high
      else
        JSONModel::init_args[:priority] == :high
      end
    end


    def self.http_conn
      @http ||= Net::HTTP::Persistent.new 'jsonmodel_client'
      @http.read_timeout = 1200
      @http
    end


    def self.do_http_request(url, req, &block)
      req['X-ArchivesSpace-Session'] = current_backend_session

      if high_priority?
        req['X-ArchivesSpace-Priority'] = "high"
      end

      response = http_conn.request(url, req, &block)

      if response.code =~ /^4/
        JSONModel::handle_error(ASUtils.json_parse(response.body))
      end
      
      response
    end


    def self.with_request_priority(priority)
      old = Thread.current[:request_priority]
      Thread.current[:request_priority] = priority
      begin
        yield
      ensure
        Thread.current[:request_priority] = old
      end
    end


    def self.post_json(url, json)
      req = Net::HTTP::Post.new(url.request_uri)
      req['Content-Type'] = 'text/json'
      req.body = json

      do_http_request(url, req)
    end


    def self.post_json_file(url, path, &block)
      File.open(path) do |fh|
        req = Net::HTTP::Post.new(url.request_uri)
        req['Content-Type'] = 'text/json'
        req['Content-Length'] = File.size(path)
        req.body_stream = fh

        do_http_request(url, req, &block)
      end
    end


    def self.delete_request(url)
      req = Net::HTTP::Delete.new(url.request_uri)

      do_http_request(url, req)
    end


    def self.get_response(url)
      req = Net::HTTP::Get.new(url.request_uri)

      do_http_request(url, req)
    end

  end



  module Client

    def self.included(base)
      base.extend(ClassMethods)
    end


    # Validate this JSONModel instance, produce a JSON string, and send an
    # update to the backend.
    def save(opts = {}, whole_body = false)

      clear_errors

      type = self.class.record_type
      response = JSONModel::HTTP.post_json(self.class.my_url(self.id, opts),
                                           self.to_json)

      if response.code == '200'
        response = ASUtils.json_parse(response.body)

        self.uri = self.class.uri_for(response["id"], opts)

        # If we were able to save successfully, increment our local version
        # number to match the version on the server.
        self.lock_version = response["lock_version"]

        # Ensure object is up to date
        if response["stale"]
          self.refetch
        end

        return whole_body ? response : response["id"]

      elsif response.code == '403'
        raise AccessDeniedException.new

      elsif response.code == '409'
        err = ASUtils.json_parse(response.body)
        raise ConflictException.new(err["error"])

      elsif response.code == '404'
        raise RecordNotFound.new

      elsif response.code =~ /^4/
        err = ASUtils.json_parse(response.body)

        if err["error"].is_a?(Hash)
          err["error"].each do |field, errors|
            errors.each do |msg|
              add_error(field, msg)
            end
          end
        end

        raise ValidationException.new(:invalid_object => self,
                                      :errors => err["error"])
      else
        raise Exception.new("Unknown response: #{response.body} (code: #{response.code})")
      end
    end


    def refetch
      # if a new object, nothing to fetch
      return self if self.id.nil?

      obj = (self.instance_data.has_key? :find_opts) ?
                self.class.find(self.id, self.instance_data[:find_opts]) : self.class.find(self.id)

      self.reset_from(obj) if not obj.nil?
    end


    def delete
      response = JSONModel::HTTP.delete_request(self.class.my_url(self.id))

      if response.code == '200'
        true
      elsif response.code == '403'
        raise AccessDeniedException.new
      elsif response.code == '404'
        nil
      elsif response.code == '409'
        err = ASUtils.json_parse(response.body)
        raise ConflictException.new(err["error"])
      else
        raise Exception.new("Unknown response: #{response}")
      end
    end

    # Mark the suppression status of this record
    def set_suppressed(val)
      response = JSONModel::HTTP.post_form("#{self.uri}/suppressed", :suppressed => val)

      if response.code == '403'
        raise AccessDeniedException.new("Permission denied when setting suppression status")
      elsif response.code != '200'
        raise "Error when setting suppression status for #{self}: #{response.code} -- #{response.body}"
      end

      self["suppressed"] = ASUtils.json_parse(response.body)["suppressed_state"]
    end


    def suppress
      set_suppressed(true)
    end


    def unsuppress
      set_suppressed(false)
    end


    def add_error(field, message)
      @errors ||= {}
      @errors[field.to_s] ||= []
      @errors[field.to_s] << message
    end


    module ClassMethods

      def self.extended(base)
        class << base
          alias :_substitute_parameters :substitute_parameters

          def substitute_parameters(uri, opts = {})
            opts = ASUtils.keys_as_strings(opts)
            if JSONModel::repository
              opts = {'repo_id' => JSONModel::repository}.merge(opts)
            end

            _substitute_parameters(uri, opts)
          end
        end
      end


      # Given the ID of a JSONModel instance, return its full URL (including the
      # URL of the backend)
      def my_url(id = nil, opts = {})
        uri, remaining_opts = self.uri_and_remaining_options_for(id, opts)
        url = URI("#{JSONModel::HTTP.backend_url}#{uri}")

        # Don't need to pass this as a URL parameter if it wasn't picked up by
        # the URI template substitution.
        remaining_opts.delete(:repo_id)

        if not remaining_opts.empty?
          url.query = URI.encode_www_form(remaining_opts)
        end

        url
      end


      # Given an ID, retrieve an instance of the current JSONModel from the
      # backend.
      def find(id, opts = {})
        response = JSONModel::HTTP.get_response(my_url(id, opts))

        if response.code == '200'
          obj = self.new(ASUtils.json_parse(response.body))
          # store find params on instance to support #refetch
          obj.instance_data[:find_opts] = opts
          obj
        elsif response.code == '403'
          raise AccessDeniedException.new
        elsif response.code == '404'
          raise RecordNotFound.new
        else
          raise response.body
        end
      end


      def find_by_uri(uri, opts = {})
        self.find(self.id_for(uri), opts)
      end


      # Return all instances of the current JSONModel's record type.
      def all(params = {}, opts = {})
        uri = my_url(nil, opts)

        uri.query = URI.encode_www_form(params)

        response = JSONModel::HTTP.get_response(uri)

        if response.code == '200'
          json_list = ASUtils.json_parse(response.body)

          if json_list.is_a?(Hash)
            json_list["results"] = json_list["results"].map {|h| self.new(h)}
          else
            json_list = json_list.map {|h| self.new(h)}
          end

          json_list
        elsif response.code == '403'
          raise AccessDeniedException.new
        else
          raise response.body
        end
      end

    end


    class EnumSource

      def self.fetch_enumerations
        enumerations = {}
        enumerations[:defaults] = {}
        JSONModel::JSONModel(:enumeration).all.each do |enumeration|
          enumerations[enumeration.name] = enumeration.values
          enumerations[:defaults][enumeration.name] = enumeration.default_value
        end

        enumerations
      end


      def initialize
        @enumerations = self.class.fetch_enumerations
      end


      def valid?(name, value)
        values_for(name).include?(value)
      end


      def values_for(name)
        @enumerations.fetch(name)
      end

      def default_value_for
        @enumerations[:defaults].fetch(name)
      end

    end


  end
end
