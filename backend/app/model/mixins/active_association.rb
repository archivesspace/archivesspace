module ActiveAssociation

  def active_association
    association_type = find_associated_type
    association_type ? self.send(association_type) : nil
  end

  def broadcast_reindex
    active_association.update(system_mtime: Time.now) if active_association
  end

  def find_associated_type
    self.class.associations.find { |type| self.send(type) }
  end

end
