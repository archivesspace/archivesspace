module RecordHelper

  def children
    return [] if @tree_view.nil?

    @children = @tree_view['direct_children'].select{|child| child["publish"] == true}

    @children
  end

  def children?
    !children.empty?
  end

end