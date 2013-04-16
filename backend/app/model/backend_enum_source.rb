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

  def self.values_for(enum_name)
    cached = @@enum_value_cache[enum_name]
    now = java.lang.System.currentTimeMillis

    if !cached || ((now - cached[:time]) > @@max_cache_ms)
      @@enum_value_cache[enum_name] = {
        :time => now,
        :value => DB.open(true) do |db|
          @@enum_value_cache[enum_name] = db[:enumeration].join(:enumeration_value, :enumeration_id => :id).
                                                           filter(:name => enum_name).
                                                           select(:value).all.map {|row| row[:value]}
        end
      }
    end

    @@enum_value_cache[enum_name][:value]
  end

end
