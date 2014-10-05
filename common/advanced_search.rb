class AdvancedSearch

  def self.define_field(opts)
    @fields ||= {}
    @fields[opts.fetch(:name).to_s] = AdvancedSearchField.new(opts)
  end


  def self.fields_matching(query)
    load_definitions

    @fields.values.select {|field|
      query.all? {|k, v| Array(field[k]).map(&:to_s).include?(v.to_s)}
    }
  end


  def self.solr_field_for(field)
    load_definitions
    @fields.fetch(field.to_s).solr_field
  end


  def self.load_definitions
    unless @loaded
      require 'search_definitions'

      ASUtils.find_local_directories("search_definitions.rb").each do |file|
        if File.exists?(file)
          load File.absolute_path(file)
        end
      end

      @loaded = true
    end
  end


  def self.set_default(type, name)
    raise "Unknown field: #{name}" unless @fields.has_key?(name)

    @fields.values.each do |field|
      if field.type == type.to_s
        field.is_default = (field.name == name)
      end
    end
  end


  AdvancedSearchField = Struct.new(:name, :type, :visibility, :solr_field, :is_default) do

    def initialize(opts)
      opts.each do |k, v|
        self.send("#{k}=".intern, v)
      end
    end


    def type=(val)
      s = val.to_s
      raise "Invalid advanced search field type: #{val}" unless ['text', 'date', 'boolean', 'enum'].include?(s)
      self[:type] = s
    end


    def visibility=(vals)
      self[:visibility] = vals.map(&:to_s)

      self[:visibility].each do |val|
        raise "Invalid advanced search field visibility: #{val}" unless ['staff', 'public'].include?(val)
      end
    end

  end

end
