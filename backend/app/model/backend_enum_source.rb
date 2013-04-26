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
            db[:enumeration_value].insert(:enumeration_id => enum_id,
                                          :value => value)
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
      self.values_for(enum_name).include?(value)
    end

  end


  @@enum_value_cache = Rufus::Lru::SynchronizedHash.new(1024)
  @@max_cache_ms = 5000


  def self.cache_entry_for(enum_name, force_refresh = false)
    cached = @@enum_value_cache[enum_name]
    now = java.lang.System.currentTimeMillis

    if force_refresh || !cached || ((now - cached[:time]) > @@max_cache_ms)
      @@enum_value_cache[enum_name] = {
        :time => now,
        :entry => DB.open(true) do |db|

          values = {}
          db[:enumeration].join(:enumeration_value, :enumeration_id => :id).
                           filter(:name => enum_name).
                           select(:value, Sequel.qualify(:enumeration_value, :id)).
                           all.each do |row|
            values[row[:value]] = row[:id]
          end

          {:values => values.keys, :value_to_id_map => values}
        end
      }
    end

    @@enum_value_cache[enum_name][:entry]
  end


  def self.values_for(enum_name)
    self.cache_entry_for(enum_name)[:values]
  end


  def self.id_for_value(enum_name, value)
    result = self.cache_entry_for(enum_name)[:value_to_id_map][value]

    if !result
      # skip the cache
      self.cache_entry_for(enum_name, true)[:value_to_id_map][value]
    end

    result
  end
end
