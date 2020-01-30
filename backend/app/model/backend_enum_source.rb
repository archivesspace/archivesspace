require 'rufus/lru'

class BackendEnumSource

  def self.valid?(enum_name, value)
    if RequestContext.get(:create_enums)
      # Some cheeky caching on the RequestContext here.  The batch import
      # process can need to check/create an awful lot of enums, so don't insert
      # into the database unless we really need to.
      #
      created = RequestContext.get(:created_enums) || {}
      RequestContext.put(:created_enums, created)

      if !Array(created[enum_name]).include?(value)
        # The customer is always right!
        DB.open(true) do |db|
          enum_id = db[:enumeration].filter(:name => enum_name).select(:id).first[:id]

          raise "Couldn't find enum: #{enum_name}" if !enum_id

          DB.attempt {
            sibling = db[:enumeration_value].filter(:enumeration_id => enum_id).order(:position).last
            if sibling
              position = sibling[:position] + 1
            else
              position = 0
            end
            
            db[:enumeration_value].insert(:enumeration_id => enum_id,
                                          :value => value,
                                          :position => position)
            @@enum_value_cache.delete(enum_name)
            Enumeration.broadcast_changes
          }.and_if_constraint_fails do
            # Must already be there.  No problem.
          end
        end

        created[enum_name] ||= []
        created[enum_name] << value
      end

      true
    else
      # force refresh of enumeration b4 validating
      self.values_for(enum_name, true).include?(value)
    end
  end


  @@enum_value_cache = Rufus::Lru::SynchronizedHash.new(16384)
  @@max_cache_ms = 300000


  def self.cache_entry_for(enum_name, force_refresh = false)
    cached = @@enum_value_cache[enum_name]
    now = java.lang.System.currentTimeMillis

    if force_refresh || !cached || ((now - cached[:time]) > @@max_cache_ms)
      @@enum_value_cache[enum_name] = {
        :time => now,
        :entry => DB.open(true) do |db|

          value_to_id_map = {}
          id_to_value_map = {}
          editable = true 
          db[:enumeration].join(:enumeration_value, :enumeration_id => :id).
                           filter(:name => enum_name).
                           order(:position).
                           select(:value, Sequel.qualify(:enumeration_value, :id), :editable).
                           all.each do |row|
            value_to_id_map[row[:value]] = row[:id]
            id_to_value_map[row[:id]] = row[:value]
            editable = ( row[:editable] === 1 or row[:editable] == true )  
          end

          {
            :values => value_to_id_map.keys,
            :value_to_id_map => value_to_id_map,
            :id_to_value_map => id_to_value_map,
            :editable => editable 
          }
        end
      }
    end

    @@enum_value_cache[enum_name][:entry]
  end


  def self.values_for(enum_name, force_refresh = false)
    self.cache_entry_for(enum_name, force_refresh)[:values]
  end

  def self.editable?(enum_name)
    (  self.cache_entry_for(enum_name)[:editable] === 1 or self.cache_entry_for(enum_name)[:editable] == true )
  end

  
  def self.id_for_value(enum_name, value)
    result = self.cache_entry_for(enum_name)[:value_to_id_map][value]

    if !result
      result = self.cache_entry_for(enum_name, true)[:value_to_id_map][value]
    end

    result
  end


  def self.values_for_ids(ids)
    result = {}

    DB.open(true) do |db|
      db[:enumeration_value].filter(:id => ids).each do |row|
        result[row[:id]] = row[:value]
      end
    end

    result
  end


  # Return the string value for a given enumeration value ID.
  #
  # `enum_names` is a list of the enumeration names that the ID might belong to.
  # For legacy reasons it can be a string (a single enumeration name), but can
  # also take an array of strings (meaning "the value belongs to one of these
  # enumerations, but I'm not sure which one).
  def self.value_for_id(enum_names, id)
    return nil if id.nil?

    enum_names = Array(enum_names)

    # If multiple possible enum names are given, try hitting the cached values
    # for all of them before giving up and hitting the DB.
    [false, true].each do |force_refresh|
      enum_names.each do |enum_name|
        result = self.cache_entry_for(enum_name, force_refresh)[:id_to_value_map][id]
        return result if result
      end
    end

    nil
  end

end
