# Mixin for clients wanting to filter out unpublished data from
# JSONModel objects


module JSONModelPublishing

  def to_hash(mode = nil)
    strip = false

    if mode == :publishing
      mode = nil
      strip = true
    end

    hash = super

    if strip
      JSONModelPublishing._drop_unpublished(hash)
    end

    hash

  end


  def self._drop_unpublished(obj)
    if obj.is_a?(Array)
      obj.reject!{|item| self._drop_unpublished(item) }
      obj.each do |value|
        self._drop_unpublished(value)
      end
    elsif obj.is_a?(Hash)
      return true if obj.has_key?('publish') && !obj['publish']
      obj.reject! {|k, v| self._drop_unpublished(v) }
      self._drop_unpublished(obj.values)
    end

    false
  end

end
