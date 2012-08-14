require 'net/http'
require 'json'


module JSONModel

  # Set the repository that subsequent operations will apply to.
  def self.set_repository(id)
    Thread.current[:selected_repo_id] = id
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


  @@protected_fields << "uri"


  module Client

    def self.included(base)
      base.extend(ClassMethods)
    end


    # Validate this JSONModel instance, produce a JSON string, and send an
    # update to the backend.
    def save(opts = {})

      @errors = nil

      type = self.class.record_type
      response = self.class._post_json(self.class.my_url(self.id, opts), self.to_json)

      if response.code == '200'
        response = JSON.parse(response.body)

        self.uri = self.class.uri_for(response["id"], opts)

        return response["id"]
      elsif response.code =~ /^4/
        err = JSON.parse(response.body)

        @errors = err["error"]

        raise ValidationException.new(:invalid_object => self,
                                      :errors => err["error"])
      else
        raise Exception.new("Unknown response: #{response}")
      end
    end


    module ClassMethods

      def self.extended(base)
        class << base
          alias :_substitute_parameters :substitute_parameters

          def substitute_parameters(uri, opts = {})
            if not opts.has_key?(:repo_id)
              opts[:repo_id] = Thread.current[:selected_repo_id]
            end

            _substitute_parameters(uri, opts)
          end
        end
      end


      # Given the ID of a JSONModel instance, return its full URL (including the
      # URL of the backend)
      def my_url(id = nil, opts = {})

        if Module.const_defined?(:BACKEND_SERVICE_URL)
          backend = BACKEND_SERVICE_URL
        else
          backend = JSONModel::init_args[:url]
        end

        url = URI("#{backend}#{self.uri_for(id, opts)}")

        # Don't need to pass this as a URL parameter if it wasn't picked up by
        # the URI template substitution.
        opts.delete(:repo_id)

        if not opts.empty?
          url.query = URI.encode_www_form(opts)
        end

        url
      end


      # Given an ID, retrieve an instance of the current JSONModel from the
      # backend.
      def find(id, opts = {})
        response = self._get_response(my_url(id, opts))

        if response.code == '200'
          self.from_json(response.body)
        elsif response.code == '404'
          nil
        else
          raise response.body
        end
      end


      # Return all instances of the current JSONModel's record type.
      # FIXME: This will need some sort of pagination support.
      def all(params = {}, opts = {})
        uri = my_url(nil, opts)

        uri.query = URI.encode_www_form(params)

        response = self._get_response(uri)

        if response.code == '200'
          json_list = JSON(response.body)

          json_list.map {|h| self.from_hash(h)}
        else
          raise response.body
        end
      end


      # Returns the session token to be sent to the backend when making
      # requests.
      def _current_backend_session
        # Set by the ApplicationController
        Thread.current[:backend_session]
      end


      def _do_http_request(url, req)
        req['X-ArchivesSpace-Session'] = _current_backend_session

        Net::HTTP.start(url.host, url.port) do |http|
          http.request(req)
        end
      end


      def _post_json(url, json)
        req = Net::HTTP::Post.new(url.request_uri)
        req.body = json

        _do_http_request(url, req)
      end


      def _get_response(url)
        req = Net::HTTP::Get.new(url.request_uri)

        _do_http_request(url, req)
      end

    end

  end
end
