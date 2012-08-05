require 'net/http'
require 'json'


module JSONModel


  module Client

    def self.included(base)
      base.extend(ClassMethods)
    end


    # class << self
    #   attr_accessor :types
    # end

    # self.types = {}


    # def persisted?
    #   false
    # end


    def save(opts = {})
      type = self.class.record_type

      response = self.class._post_json(self.class.my_url(self.id, opts), self.to_json)

      if response.code == '200'
        response = JSON.parse(response.body)

        return response["id"]
      elsif response.code == '409'
        # A conflict exception
        err = JSON.parse(response.body)

        raise ValidationException.new(:invalid_object => self,
                                      :errors => err["error"])
      else
        raise Exception.new("Unknown response: #{response}")
      end
    end


    def id=(id)
      @id = id
    end


    def id
      @id
    end



    module ClassMethods

      def get_globals
        {:repo_id => Thread.current[:selected_repo_id]}
      end


      def my_url(id = nil, opts = {})
        url = "#{BACKEND_SERVICE_URL}#{self.uri_for(id, opts)}"

        URI(url)
      end


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


      def find(id, opts = {})
        response = self._get_response(my_url(id, opts))

        if response.code == '200'
          obj = self.from_json(response.body)
          obj.id = id

          obj
        else
          nil
        end
      end


      def all(opts = {})
        uri = my_url

        uri.query = URI.encode_www_form(opts)

        response = self._get_response(uri)

        if response.code == '200'
          json_list = JSON(response.body)

          json_list.map {|h| self.from_hash(h)}
        else
          nil
        end
      end

    end

  end
end
