# container for handling facet, filter information
class FacetFilter < Struct.new( :default_types, :filters, :facet_types, :facet_set_arr)
  include ManipulateNode
  include HandleFaceting

  def initialize(default_types, filters = [])
    self.default_types = default_types || []
    self.filters = Array.new(filters || [])
    self.facet_types = default_types - (filters.collect! { |f| f.split(":")[0]})
    self.facet_set_arr = []
  end
  
  # an array of strings for asking for filtering
  def get_facet_types
    self.facet_types
  end

  # returns a hash of a hash of the filters, with facet type as key, pt as the printable type
  # pv as the printable value, v as the value of the filter
  def get_filter_hash
    fh = {}
    self.filters.each do |f|
      k,*v = f.split(":")
      v = v.join(":").to_s if v.kind_of? Array  # just in case there's a colon or two buried in the value
      pt = I18n.t("search_results.filter.#{k}")
      pv = get_pretty_facet_value(k, v.sub(/"(.*)"/,'\1'))
      fh[k] = {'v' => v, 'pv' => pv, 'pt' => pt }
    end
    fh
  end
end
