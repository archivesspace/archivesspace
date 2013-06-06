require 'java'
require 'tmpdir'
require 'config/config-distribution'

module ASUtils

  def self.keys_as_strings(hash)
    result = {}

    hash.each do |key, value|
      result[key.to_s] = value
    end

    result
  end


  def self.as_array(thing)
    return [] if thing.nil?
    thing.kind_of?(Array) ? thing : [thing]
  end


  def self.jsonmodels_to_hashes(elt)

    if elt.is_a?(JSONModel::JSONModelType)
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


  def self.to_json(obj, opts = {})
    if obj.respond_to?(:jsonize)
      obj.jsonize(opts.merge(:max_nesting => false))
    else
      obj.to_json(opts.merge(:max_nesting => false))
    end
  end


  def self.find_local_directories(base = nil)
    [File.join(File.dirname(__FILE__), ".."),
     java.lang.System.get_property("ASPACE_LAUNCHER_BASE"),
     java.lang.System.get_property("catalina.base")].
      reject { |dir| !Dir.exists?(dir) }.
      map { |dir| Array(AppConfig[:plugins]).map { |plugin| File.join(*[dir, "plugins", plugin, base].compact) } }.flatten
  end


  def self.find_locales_directories(base = nil)
    [File.join(File.dirname(__FILE__), "..", "common"),
           java.lang.System.get_property("ASPACE_LAUNCHER_BASE"),
           java.lang.System.get_property("catalina.base")].
        reject { |dir| !Dir.exists?(dir) }.
        map { |dir| File.join(*[dir, "locales", base].compact) }
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


  def self.dump_diagnostics(exception = nil)
    runtime = java.lang.Runtime.getRuntime
    diagnostics = {
      :environment => java.lang.System.getenv,
      :jvm_properties => java.lang.System.getProperties,
      :globals => Hash[global_variables.map {|v| [v, eval(v.to_s)]}],
      :appconfig => defined?(AppConfig) ? AppConfig.dump_sanitised : "not loaded",
      :memory => {
        :free => runtime.freeMemory,
        :max => runtime.maxMemory,
        :total => runtime.totalMemory
      },
      :cpu_count => runtime.availableProcessors,
      :exception => exception && {:msg => exception, :backtrace => exception.backtrace}
    }

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

end
