class EnumerationValue < Sequel::Model(:enumeration_value)
  include ASModel
  corresponds_to JSONModel(:enumeration_value)
  set_model_scope :global
  
  many_to_one :enumeration
  
  enable_suppression 

  def before_create
    # bit clunky but this allows us to make sure that bulk updates are
    # positioned correctly 
    unless self.position 
      self.position = rand(100) + 1000000 # lets just give it a randomly high number
    end
    obj = super
    # now let's set it in the list
    100.times do
       DB.attempt {
          sibling = self.class.dataset.filter( :enumeration_id => self.enumeration_id).order(:position).last
          if sibling
            self.class.dataset.db[self.class.table_name].filter(:id => self.id ).update(:position => sibling[:position] + 1)
          else
            self.class.dataset.db[self.class.table_name].filter(:id => self.id ).update(:position => 0 )
          end
          return 
       }.and_if_constraint_fails {
          # another transaction has slipped in...let's try again 
       }
    end
    obj
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
