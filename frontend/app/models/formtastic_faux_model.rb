# -------------------------------------------------------------------------------
# Faux model object that plays well with formtastic; this is used for example in
# a contact form which generates a request to salesforce
#
#  Created: by dondoh
#  Website: http://dondoh.tumblr.com/post/4142258573/formtastic-without-activerecord
# -------------------------------------------------------------------------------
class FormtasticFauxModel
  include ActiveModel::Validations
  include ActiveModel::Conversion  
  extend  ActiveModel::Naming

  # Subclass may provide a types hash.  Any attributes not listed will
  # default to string.
  # self.types = {
  #   :description => :text,
  #   :state => {:type => :string, :limit => 2}
  #   :country => :string,
  #   :newsletter_opt_in => :boolean,
  # }

  class << self
    attr_accessor :types
  end
  self.types = {}

  # So the controller can say "@contact = Contact.new(params[:contact])"
  def initialize(attributes = {})  
    attributes.each do |name, value|  
      send("#{name}=", value)
    end
  end  

  # So form_for works correctly -- we only do "new" forms
  def persisted?  ;   false  ;    end  

  # To provide the type information
  def column_for_attribute(attr)
    FauxColumnInfo.new(self.class.types[attr])
  end

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
end