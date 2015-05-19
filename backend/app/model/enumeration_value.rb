class EnumerationValue < Sequel::Model(:enumeration_value)
  include ASModel
  corresponds_to JSONModel(:enumeration_value)
  set_model_scope :global
  
  many_to_one :enumeration
  
  enable_suppression 

  def before_create
    unless self.position
      sibling = self.class.dataset.filter( :enumeration_id => self.enumeration_id).order(:position).last
      if sibling 
        self.position = sibling[:position] + 1
      end 
    end
    super 
  end

  def update_position_only(target_position )
    # we need to swap places with what we're trying to replace.
    current_position = self.position 
    sibling = self.class.dataset.filter( :enumeration_id => self.enumeration_id, :position => target_position ).first
   
    if sibling
      self.class.dataset.filter( :enumeration_id => self.enumeration_id, :position => target_position ).update(:position => Sequel.lit('position + 9999' ))
    end 
   
    self.class.dataset.filter( :id => self.id ).update( :position => target_position )
    self.class.dataset.filter( :id => sibling.id ).update( :position => current_position ) if sibling
    self.enumeration.class.broadcast_changes   
    
    target_position 
  end

  def self.handle_suppressed(ids, val)
    obj = super
    Enumeration.broadcast_changes   
    obj 
  end


end
