require 'net/http'
require 'json'

class Subject < JSONModel(:subject)
  attr_accessor :display_string


  def display_string
    return @display_string if @display_string
    @display_string = terms.collect {|t| t["term"]}.join(" -- ")
    @display_string
  end

  def to_hash
    hash = super
    hash["display_string"] = display_string
    hash
  end


end
