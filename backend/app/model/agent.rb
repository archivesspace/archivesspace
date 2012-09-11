module Agent

  def one_to_many_relationship(opts)
    one_to_many opts[:table], :class => opts[:class]

    if opts[:table] != opts[:plural_type]
      alias_method opts[:plural_type], opts[:table]
      alias_method :"remove_all_#{opts[:plural_type]}", :"remove_all_#{opts[:table]}"
      alias_method :"#{opts[:plural_type]}_dataset", :"#{opts[:table]}_dataset"
      alias_method :"add_#{opts[:type]}", :"add_#{opts[:table]}"
    end
  end

end
