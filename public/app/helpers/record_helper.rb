module RecordHelper

  def whole_tree?
    !whole_tree.empty?
  end

  def whole_tree
    return [] if @tree_view.nil? || @tree_view['whole_tree'].nil?

    @tree_view['whole_tree']
  end


  def children
    return [] if @tree_view.nil?

    @children = @tree_view['direct_children'].select{|child| child["publish"] == true}

    @children
  end

  def children?
    !children.empty?
  end

end
