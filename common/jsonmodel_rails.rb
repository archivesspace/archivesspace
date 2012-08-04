# Rails mixin for JSONModel
# -------------------------------------------------------------------------------
# Parts of this file are borrowed from Dondoh's Faux model object.
#
#  Created: by dondoh
#  Website: http://dondoh.tumblr.com/post/4142258573/formtastic-without-activerecord
#  Licence: Under the following conditions:
#
#            * Attribution -- you must attribute the work to me (a comment in
#              the code is sufficient, although I would also accept a role in
#              the movie adaptation)
#
#            * Share alike -- if you alter, transform, or build upon this work,
#              you may distribute the work only under the same or similar
#              license to this one.
#
# -------------------------------------------------------------------------------


require 'net/http'
require 'json'


module JSONModel

  class FauxColumnInfo
    attr_accessor :type, :limit

    def initialize(type_info)
      type_info ||= :string
      case
      when  type_info.instance_of?(Hash), type_info.instance_of?(OpenStruct)
        self.type = type_info[:type].to_sym
        self.limit = type_info[:limit]
      else
        self.type = type_info.to_sym
        self.limit = nil
      end
    end
  end


  module Rails

    def self.included(base)
      base.extend(ClassMethods)
    end


    class << self
      attr_accessor :types
    end

    self.types = {}


    def persisted?
      false
    end


    def column_for_attribute(attr)
      JSONModel::FauxColumnInfo.new(self.class.types[attr])
    end


    def save(opts = {})
      type = self.class.record_type

      response = self.class._post_json(self.class.my_url(self.id), self.to_json)

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

      def my_url(id = nil)
        uri = "#{BACKEND_SERVICE_URL}#{self.schema['uri']}"

        uri = uri.gsub(':repo_id', Thread.current[:selected_repo_id].to_s)

        if id
          uri += "/#{id}"
        end

        URI(uri)
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


      def find(id)
        response = self._get_response(my_url(id))

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
