require 'atomic'
require 'thread'

module MemoryLeak

  class Resources

    @@refresh_mutex = Mutex.new

    @@resources = {}
    @@refresh_fns = {}
    @@expiration_seconds = {}


    def self.define(resource, refresh_fn, ttl, opts = {})
      @@resources[resource] = Atomic.new(nil)
      @@refresh_fns[resource] = refresh_fn
      @@expiration_seconds[resource] = ttl if ttl

      self.set(resource, opts[:init], 0)
    end


    def self.get(resource)
      stale = (@@resources[resource].value.nil? ||
               (@@expiration_seconds[resource] &&
                (Time.now.to_i - @@resources[resource].value[:system_mtime]) > @@expiration_seconds[resource]))

      self.refresh(resource) if stale

      @@resources[resource].value[:value]
    end


    def self.refresh(resource)
      # Two concurrent users might trigger some resource to be refreshed at
      # around the same time (e.g. when two people create a new repository at
      # once).  We want both refreshes to run in sequence, so use a mutex to
      # serialize them.
      @@refresh_mutex.synchronize do
        self.set(resource, @@refresh_fns[resource].call)
      end
    end


    def self.set(resource, value, time = nil)
      @@resources[resource].swap({:value => value, :system_mtime => (time || Time.now.to_i)})
    end


    def self.invalidate_all!
      @@resources.values.each do |atom|
        atom.update {|val| val.merge(:system_mtime => 0) if val}
      end
    end

  end

end
