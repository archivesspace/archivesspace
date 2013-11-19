module Instances

  def self.included(base)
    require_relative '../instance'

    base.one_to_many :instance
    Instance.many_to_one base.table_name

    base.def_nested_record(:the_property => :instances,
                           :contains_records_of_type => :instance,
                           :corresponding_to_association => :instance)


    def eagerly_load!
      Instance.eager_load_relationships(self.instance)
      super
    end

  end

end
