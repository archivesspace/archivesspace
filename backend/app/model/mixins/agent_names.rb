module AgentNames

  def self.included(base)
    base.set_model_scope :global
    
    base.one_to_many :date, :class => "ASDate"
    
    base.def_nested_record(:the_property => :use_dates,
                           :contains_records_of_type => :date,
                           :corresponding_to_association => :date)


    base.one_to_one :name_authority_id

    base.extend(ClassMethods)
  end


  def before_validation
    super

    # force to NULL (not 0) to make sure uniqueness constraints work as
    # desired.
    self.authorized = nil if self.authorized != 1
    self.is_display_name = nil if self.is_display_name != 1
  end


  def update_from_json(json, opts = {}, apply_nested_records = true)
    obj = super
    self.class.apply_authority_id(obj, json)
  end


  def remove_nested_records
    name_authority_id_dataset.delete
    super
  end


  module ClassMethods

    def apply_authority_id(obj, json)
      obj.name_authority_id_dataset.delete

      if json['authority_id']
        obj.name_authority_id = NameAuthorityId.create(:authority_id => json['authority_id'],
                                                       :lock_version => 0)
      end

      obj
    end


    def create_from_json(json, opts = {})
      obj = super
      apply_authority_id(obj, json)
    end


    def sequel_to_jsonmodel(obj, opts = {})
      json = super

      if obj.name_authority_id
        json['authority_id'] = obj.name_authority_id.authority_id
      end

      json
    end
  end


end
