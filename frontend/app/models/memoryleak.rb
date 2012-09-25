require 'atomic'

module MemoryLeak

  class Resources

    @@resources = {
      :repository => Atomic.new(nil),
      :vocabulary => Atomic.new(nil),
      :acl_last_modified => Atomic.new({:last_modified => 0, :value => 0})
    }

    @@expiration_seconds = {
      :repository => 60,
      :vocabulary => 60
    }

    def self.get(resource)
      stale = (@@resources[resource].value.nil? ||
               (@@expiration_seconds[resource] &&
                (Time.now.to_i - @@resources[resource].value[:last_modified]) > @@expiration_seconds[resource]))

      self.refresh(resource) if stale

      @@resources[resource].value[:value]
    end


    def self.refresh(resource)
      self.set(resource, JSONModel(resource).all)
    end


    def self.set(resource, value)
      @@resources[resource].swap({:value => value, :last_modified => Time.now.to_i})
    end


    def self.invalidate_all!
      @@resources.values.each do |atom|
        atom.update {|val| val.merge(:last_modified => 0) if val}
      end
    end

  end

end
