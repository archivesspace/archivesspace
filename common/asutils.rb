# Note: ASUtils gets pulled in all over the place, and in some places prior to
# any gems having been loaded.  Be careful about loading gems here, as the gem
# path might not yet be configured.  For example, loading the 'json' gem can
# cause you to pull in the version that ships with JRuby, rather than the one in
# your Gemfile.

require 'java'
require 'tmpdir'
require 'tempfile'
require 'config/config-distribution'

module ASUtils

  def self.keys_as_strings(hash)
    result = {}

    hash.each do |key, value|
      result[key.to_s] = value.is_a?(Date) ? value.to_s : value 
    end

    result
  end


  def self.as_array(thing)
    return [] if thing.nil?
    thing.kind_of?(Array) ? thing : [thing]
  end


  def self.jsonmodels_to_hashes(elt)

    if elt.is_a?(JSONModelType)
      elt = elt.to_hash(:raw)
    end

    if elt.is_a?(Hash)
      Hash[elt.map {|k, v| [k, self.jsonmodels_to_hashes(v)]}]
    elsif elt.is_a?(Array)
      elt.map {|v| self.jsonmodels_to_hashes(v)}
    else
      elt
    end
  end


  def self.json_parse(s)
    JSON.parse(s, :max_nesting => false, :create_additions => false)
  end


  # A bit funny to wrap this ourselves, but there's an interesting case when
  # running under rspec.
  #
  # Rspec reseeds the random number generator at the beginning of every suite
  # run, which means that Tempfile's "random" filenames are often IDENTICAL
  # between subsequent Tempfile invocations across test runs.
  #
  # This shouldn't really matter, except when this happens:
  #
  #  * Test1 runs and produces tempfile "somerandomfile", which gets closed and
  #    unlinked.
  #
  #  * Test2 runs and gets given "somerandomfile" too.  It starts working with it.
  #
  #  * Then, bam!  Garbage collection runs, and finalizes the object from Test1.
  #    This unlinks the underlying temp file while Test2 is still using it!
  #
  # So yeah, not cool.  We try to inject a little randomness into "base" to
  # avoid these sort of shenanigans, even though it really shouldn't matter in
  # production.
  def self.tempfile(base)
    Tempfile.new("#{base}_#{java.lang.System.currentTimeMillis}")
  end


  def self.to_json(obj, opts = {})
    if obj.respond_to?(:jsonize)
      obj.jsonize(opts.merge(:max_nesting => false))
    else
      obj.to_json(opts.merge(:max_nesting => false))
    end
  end


  def self.find_base_directory(root = nil)
    # JRuby 9K seems to be adding this strange suffix...
    #
    # Example: /pat/to/archivesspace/backend/uri:classloader:
    this_dir = __dir__.gsub(/uri:classloader:\z/, '')

    res = [java.lang.System.get_property("ASPACE_LAUNCHER_BASE"),
     java.lang.System.get_property("catalina.base"),
     File.join(*[this_dir, "..", root].compact)].find {|dir|
      dir && Dir.exist?(dir)
    }

    res
  end


  def self.find_local_directories(base = nil, *plugins)
    plugins = AppConfig[:plugins] if plugins.empty?
    base_directory = self.find_base_directory
    Array(plugins).map { |plugin| File.join(*[base_directory, "plugins", plugin, base].compact) }
  end


  def self.find_locales_directories(base = nil)
    [File.join(*[self.find_base_directory("common"), "locales", base].compact)]
  end


  def self.extract_nested_strings(coll)
    if coll.is_a?(Hash)
      coll.values.map {|v| self.extract_nested_strings(v)}.flatten.compact
    elsif coll.is_a?(Array)
      coll.map {|v| self.extract_nested_strings(v)}.flatten.compact
    else
      coll
    end
  end

 def self.get_diagnostics(exception = nil )
    runtime = java.lang.Runtime.getRuntime
   {
      :version =>ASConstants.VERSION,
      :appconfig => defined?(AppConfig) ? AppConfig.dump_sanitized : "not loaded",
      :memory => {
        :free => runtime.freeMemory,
        :max => runtime.maxMemory,
        :total => runtime.totalMemory
      },
      :cpu_count => runtime.availableProcessors,
      :exception => exception && {:msg => exception, :backtrace => exception.backtrace}
    }
   
 end

  def self.dump_diagnostics(exception = nil)
    diagnostics = self.get_diagnostics( exception ) 
    tmp = File.join(Dir.tmpdir, "aspace_diagnostic_#{Time.now.to_i}.txt")
    File.open(tmp, "w") do |fh|
      fh.write(JSON.pretty_generate(diagnostics))
    end

    msg = <<EOF
A trace file has been written to the following location: #{tmp}

This file contains information that will assist developers in diagnosing
problems with your ArchivesSpace installation.  Please review the file's
contents for sensitive information (such as passwords) that you might not
want to share.
EOF

    $stderr.puts("=" * 72)
    $stderr.puts(msg)
    $stderr.puts("=" * 72)

    raise exception if exception
  end


  # Recursively overlays hash2 onto hash 1
  def self.deep_merge(hash1, hash2)
    target = hash1.dup
    hash2.keys.each do |key|
      if hash2[key].is_a? Hash and hash1[key].is_a? Hash
        target[key] = self.deep_merge(target[key], hash2[key])
        next
      end
      target[key] = hash2[key]
    end
    target
  end


  def self.load_plugin_gems(context)
    ASUtils.find_local_directories.each do |plugin|
      gemfile = File.join(plugin, 'Gemfile')
      if File.exist?(gemfile)
        context.instance_eval(File.read(gemfile))
      end
    end
  end


  # Borrowed from: file activesupport/lib/active_support/core_ext/array/wrap.rb, line 36
  def self.wrap(object)
    if object.nil?
      []
    elsif object.respond_to?(:to_ary)
      object.to_ary || [object]
    else
      [object]
    end
  end

  # Recursively find any hash entry whose key is in `keys`.  When we find a
  # match, call `block` with the key and value as arguments.
  #
  # Skips descending into any hash entry whose key is in `ignore_keys` (allowing
  # us to avoid walking '_resolved' subtrees, for example)
  def self.search_nested(elt, keys, ignore_keys = [], &block)
    if elt.respond_to?(:key?)
      keys.each do |key|
        if elt.key?(key)
          block.call(key, elt.fetch(key))
        end
      end

      elt.each.each do |next_key, value|
        unless ignore_keys.include?(next_key)
          search_nested(value, keys, ignore_keys, &block)
        end
      end
    elsif elt.respond_to?(:each)
      elt.each do |value|
        search_nested(value, keys, ignore_keys, &block)
      end
    end
  end

  # recursively walk `obj` and remove any hash entry whose key returns `true`
  # for `block.call(key)`.
  #
  # `obj` can be an arbitrarily nested combination of array-like and hash-like
  # things.
  def self.recursive_reject_key(obj, &block)
    if obj.nil? || block.nil?
      obj
    elsif obj.respond_to?(:each_pair)
      result = {}
      obj.each_pair do |k, v|
	if !block.call(k)
	  result[k] = recursive_reject_key(v, &block)
	end
      end
      result
    elsif obj.respond_to?(:map)
      obj.map { |elt| recursive_reject_key(elt, &block) }
    else
      obj
    end
  end

  def self.blank?(obj)
    if obj.nil?
      true
    elsif obj.respond_to?(:empty?)
      !!obj.empty?
    else
      !obj
    end
  end

  def self.present?(obj)
    !blank?(obj)
  end

end
