module Agent

  def one_to_many_relationship(opts)
    one_to_many opts[:table], :class => opts[:class]
  end

end
