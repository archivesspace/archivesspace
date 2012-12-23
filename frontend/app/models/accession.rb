class Accession < JSONModel(:accession)
  attr_accessor :resource_link

  def resource_link
    if @resource_link.blank? then
      @resource_link = "defer"
    end
    @resource_link
  end
  
  def ref_id
    ref_id = ""
    
    (0..3).each do |i|
      next if self.send("id_#{i.to_s}").blank?
      ref_id << " - " unless i === 0
      ref_id << self.send("id_#{i.to_s}")
    end
    
    ref_id
  end
end
