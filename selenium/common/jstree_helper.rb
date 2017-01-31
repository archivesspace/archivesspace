module JSTreeHelperMethods

  class JSNode
    def initialize(obj)
      @obj = obj
    end

    def li_id
      "#{@obj.jsonmodel_type}_#{@obj.class.id_for(@obj.uri)}"
    end

    def a_id
      "#{self.li_id}_anchor"
    end

  end


  def js_node(obj)
    JSNode.new(obj)
  end
end
