module AutoGenerator

  def self.included(base)
    base.extend(ClassMethods)
  end

  def update_from_json(json, opts = {}, apply_nested_records = true)
    self.class.properties_to_auto_generate.each do |generate_opts|
      next if generate_opts[:only_if] and not generate_opts[:only_if].call(json)

      if generate_opts[:only_on_create]
        # force the value back to the original value from the DB
        json[generate_opts[:property]] = self.send(generate_opts[:property])
      else
        next if generate_opts[:only_if_nil] and not json[generate_opts[:property]].nil?

        # generate a new value
        json[generate_opts[:property]] = generate_opts[:generator].call(json)
        mark_as_system_modified
      end
    end

    super
  end


  module ClassMethods

    def create_from_json(json, opts = {})
      modified = false

      properties_to_auto_generate.each do |generate_opts|
        if (generate_opts[:only_if] and generate_opts[:only_if].call(json)) or json[generate_opts[:property]].nil?
          json[generate_opts[:property]] = generate_opts[:generator].call(json)
          modified = true
        end
      end

      obj = super

      obj.mark_as_system_modified if modified

      obj
    end


    def auto_generate(opts)
      properties_to_auto_generate.delete_if{|generate_opts| generate_opts[:property] == opts[:property] }
      properties_to_auto_generate.push(opts)
    end


    def properties_to_auto_generate
      @properties_to_auto_generate ||= []

      @properties_to_auto_generate
    end

  end

end
