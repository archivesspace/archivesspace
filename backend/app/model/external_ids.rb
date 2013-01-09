module ExternalIDs

  def self.included(base)

    # Generate a class for the external IDs
    table_name = "#{base.table_name}_ext_id".intern

    begin
      clz = Object.const_get(table_name.to_s.classify)
    rescue NameError
      clz = Class.new(Sequel::Model(table_name)) do
        if !self.db.table_exists?(self.table_name)
          Log.warn("Table doesn't exist: #{self.table_name}")
        end
      end

      Object.const_set(table_name.to_s.classify, clz)
    end


    base.one_to_many(table_name, :order => "#{table_name}__id".intern)

    base.instance_eval do
      alias_method :external_id, table_name.intern
      alias_method :remove_all_external_id, "remove_all_#{table_name}".intern

      define_method(:add_external_id) {|hash|
        send("add_#{table_name}".intern, clz.new(hash))
      }
    end

    base.extend(ClassMethods)
  end


  def update_from_json(json, opts = {})
    obj = super
    self.class.save_external_ids(obj, json, opts)
    obj
  end



  module ClassMethods

    def create_from_json(json, opts = {})
      obj = super
      save_external_ids(obj, json, opts)
      obj
    end


    def sequel_to_jsonmodel(obj, opts = {})
      json = super
      json['external_ids'] = obj.external_id.map {|obj| ASUtils.keys_as_strings(obj.values)}
      json
    end


    def prepare_for_deletion(dataset)
      dataset.each do |obj|
        if obj.respond_to?(:external_id)
          obj.external_id.map(&:delete)
        end
      end
    end


    def save_external_ids(obj, json, opts)
      obj.remove_all_external_id

      Array(json['external_ids']).each do |external_id|
        obj.add_external_id(external_id)
      end
    end

  end

end
