class Facet < Struct.new(:type, :key, :count, :label)
  extend HandleFaceting
  extend ManipulateNode

  def initialize(type, key, count)
    self.type = type
    self.key = key
    self.count = count
    self.label = self.class.get_pretty_facet_value(self.type, self.key)
  end
end
