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

  def jstree_click(a_id)
    100.times do
      return if @driver.find_element_orig(:css, "##{a_id}.jstree-clicked") rescue nil
      @driver.find_element(:id => a_id).click
      sleep 0.1
    end

    raise "Couldn't click JSTree ID: #{a_id}"
  end

  def js_node(obj)
    JSNode.new(obj)
  end
end
