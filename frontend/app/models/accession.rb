require 'net/http'

class Accession < JSONModel(:accession)
  attr_accessor :resource_link

  def resource_link
    if @resource_link.blank? then
      @resource_link = "defer"
    end
    @resource_link
  end
end
