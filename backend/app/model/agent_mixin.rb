module AgentMixin

  def agents_matching(query, max, name_type, name_model)
    self.where(name_type => name_model.
               where(Sequel.like(Sequel.function(:lower, :sort_name),
                                 "#{query}%".downcase))).first(max)
  end

end
