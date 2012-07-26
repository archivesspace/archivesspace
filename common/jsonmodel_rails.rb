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

    def save
      properties = self.to_hash

      type = self._record_type

      if @my_uri
        # Update
        raise Exception.new("Not implemented yet")
      else
        # Create
        uri = "#{BACKEND_SERVICE_URL}/#{type}"
      end

      response = Net::HTTP.post_form(URI(uri), {type => self.to_json})

      if response.code == '200'
        JSON.parse(response.body)
      elsif response.code == '409'
        # A conflict exception
        err = JSON.parse(response.body)

        raise ValidationException.new(:invalid_object => self,
                                      :errors => err["error"])
      else
        raise Exception.new("Unknown response: #{response}")
      end

    end
  end
end
