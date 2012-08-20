class Accession < JSONModel(:accession)
  attr_accessor :resource_link

  def collection_link
    if @collection_link.blank? then
      @collection_link = "defer"
    end
    @collection_link
  end
end
