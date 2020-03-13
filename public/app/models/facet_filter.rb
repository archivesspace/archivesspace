# container for handling facet, filter information
class FacetFilter < Struct.new( :default_types, :fields, :values, :facet_types, :facet_set_arr)
  include ManipulateNode
  include HandleFaceting

  def initialize(default_types, fields = [], values=[])
    self.default_types = default_types || []
    self.fields = Array.new(fields || [])
    self.values = Array.new(values || [])
    self.facet_types = default_types
    Rails.logger.debug("Default: #{default_types} fields: #{fields} facet_types: #{self.facet_types}")
    self.facet_set_arr = []
  end

  # an array of strings for asking for filtering
  def get_facet_types
    self.facet_types
  end

  # returns an AdvancedQueryBuilder with the filters worked in.
  def get_filter_query
    builder = AdvancedQueryBuilder.new
    self.fields.zip(self.values){|field, value| builder.and(field, value) }
    builder
  end 

  def get_filter_url_params
    param = ""
    self.fields.zip(values){|field, value| param += "&filter_fields[]=#{field}&filter_values[]=#{CGI.escape(value)}" }
    param
  end

  # returns a hash of arrays of hashes representing the selected filters and values, with filter field as the key
  # in the top-level hash, the values being arrays of selections within that filter, each of which is then a hash where
  # pt as the printable field label, pv as the printable value, v as the value of the filter
  def get_filter_hash(url = nil)
    fh = {}
    self.fields.zip(self.values) do |k, v|
      pt = I18n.t("search_results.filter.#{k}")
      pv = get_pretty_facet_value(k, v.sub(/"(.*)"/,'\1'))
      uri = (url)? url.sub("&filter_fields[]=#{k}&filter_values[]=#{CGI.escape(v)}","") : ''
      fh[k] ||= []
      fh[k].push({'v' => v, 'pv' => pv, 'pt' => pt, 'uri' => uri })
    end
    fh
  end
end
