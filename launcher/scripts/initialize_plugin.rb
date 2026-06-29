# frozen_string_literal: true

require "bundler"
require "rubygems"
require "fileutils"
require "shellwords"
require "tmpdir"
require "English"

plugin = ARGV.shift

unless plugin && !plugin.empty?
  warn "Usage: #{$PROGRAM_NAME} <plugin name>"
  exit 1
end

base = ENV["ASPACE_LAUNCHER_BASE"]
unless base && File.exist?(File.join(base, "archivesspace.sh"))
  base = File.expand_path(File.join(__dir__, "..", ".."))
end

core_gem_home = File.join(base, "gems")
core_specs_dir = File.join(core_gem_home, "specifications")
plugin_dir = File.absolute_path?(plugin) ? plugin : File.join(base, "plugins", plugin)
plugin_gemfile = File.join(plugin_dir, "Gemfile")
plugin_gem_home = File.join(plugin_dir, "gems")
install_gemfile = File.join(plugin_dir, ".aspace-plugin-install.Gemfile")

unless File.directory?(plugin_dir)
  warn "Failed to find plugin: #{plugin}"
  exit 1
end

unless File.file?(plugin_gemfile)
  warn "Failed to find plugin Gemfile: #{plugin_gemfile}"
  exit 1
end

unless File.directory?(core_specs_dir)
  warn "Failed to find ArchivesSpace gem specifications: #{core_specs_dir}"
  exit 1
end

unless system("unzip", "-v", out: File::NULL, err: File::NULL)
  warn "`unzip` is required to read war lockfiles but was not found on PATH"
  exit 1
end

# Bundler::LockfileParser instantiates Bundler::Source::Rubygems while parsing
# the GEM section, and that constructor probes Bundler.root for an app cache
# path. Bundler.root requires a Gemfile in scope. Anchor CWD at the plugin
# directory (which we just verified contains a Gemfile) so parsing succeeds
# regardless of where the wrapper script was invoked from. The rest of this
# script uses absolute paths, so changing CWD is safe.
Dir.chdir(plugin_dir)

def run_jruby(base, *args)
  java = ENV.fetch("JAVA", "java")
  classpath = ENV.fetch("ASPACE_JRUBY_CLASSPATH")
  java_opts = Shellwords.split(ENV.fetch("ASPACE_JAVA_OPTS", ""))
  cmd = [java, *java_opts, "-cp", classpath, "org.jruby.Main", *args]

  puts cmd.shelljoin if ENV["ASPACE_PLUGIN_DEBUG"] == "true"
  system(*cmd) || abort("Command failed: #{cmd.shelljoin}")
end

def load_specs(specs_dir)
  Dir[File.join(specs_dir, "*.gemspec")].filter_map do |path|
    Gem::Specification.load(path)
  rescue StandardError => e
    warn "Warning: failed to read #{path}: #{e}"
    nil
  end
end

def lock_specs(text)
  parser = Bundler::LockfileParser.new(text)
  specs = {}
  parser.specs.each do |spec|
    next unless spec.source.is_a?(Bundler::Source::Rubygems)

    version = spec.version.to_s
    specs[spec.name] ||= []
    specs[spec.name] << version unless specs[spec.name].include?(version)
  end
  specs
end

def locked_gem_names(lockfile)
  lock_specs(File.read(lockfile)).keys
end

def war_gem_versions(base)
  versions = {}

  Dir[File.join(base, "wars", "*.war")].sort.each do |war|
    lockfile = IO.popen(["unzip", "-p", war, "WEB-INF/Gemfile.lock"], &:read)
    next unless $CHILD_STATUS.success?

    lock_specs(lockfile).each do |name, locked_versions|
      versions[name] ||= []
      locked_versions.each do |version|
        versions[name] << version unless versions[name].include?(version)
      end
    end
  end

  versions
end

def gem_requirement_version(version)
  # Strip platform suffix (java, ruby, x86_64-linux, arm64-darwin, universal-java-21, etc.)
  version.sub(/-(?:java|ruby|universal-.*|x86_64-.*|arm64-.*|aarch64-.*)\z/, "")
end

core_specs = load_specs(core_specs_dir)
core_specs_by_name = core_specs.group_by(&:name)
war_versions_by_name = war_gem_versions(base)
bundler_version = core_specs_by_name.fetch("bundler").max_by(&:version).version.to_s

ENV["GEM_HOME"] = plugin_gem_home
ENV["GEM_PATH"] = [core_gem_home, plugin_gem_home].join(File::PATH_SEPARATOR)
ENV.delete("BUNDLE_PATH")

begin
  puts "Rebuilding plugin gem home: #{plugin_gem_home}"
  FileUtils.rm_rf(plugin_gem_home)
  FileUtils.mkdir_p(plugin_gem_home)

  run_jruby(base, "-S", "gem", "install", "bundler", "-v", bundler_version, "--no-document")

  File.open(install_gemfile, "w") do |file|
    file.puts %(eval_gemfile "#{plugin_gemfile}")
  end

  run_jruby(base, File.join(core_gem_home, "bin", "bundle"), "lock", "--gemfile=#{install_gemfile}")
  plugin_gem_names = locked_gem_names("#{install_gemfile}.lock")
  FileUtils.rm_f("#{install_gemfile}.lock")

  # Bundler can resolve only one version for a gem. Constrain plugin resolution
  # to the ArchivesSpace WAR-pinned version only for gems that the plugin's
  # dependency graph selected and where the WAR lockfiles agree. If WARs pin
  # multiple versions, leave the plugin's selected version alone; another WAR may
  # need that version available from the plugin gem home.
  constraints = plugin_gem_names.filter_map do |name|
    versions = war_versions_by_name[name]
    next unless versions
    next unless versions.length == 1

    %(gem "#{name}", "= #{gem_requirement_version(versions.first)}", require: false)
  end.sort

  if ENV["ASPACE_PLUGIN_DEBUG"] == "true"
    puts "Plugin dependency graph includes #{plugin_gem_names.length} gems"
    puts "Applying #{constraints.length} ArchivesSpace core constraints"
    constraints.each { |constraint| puts "\t#{constraint}" }
  end

  File.open(install_gemfile, "w") do |file|
    file.puts %(eval_gemfile "#{plugin_gemfile}")
    constraints.each { |constraint| file.puts constraint }
  end

  run_jruby(base, File.join(core_gem_home, "bin", "bundle"), "install", "--gemfile=#{install_gemfile}")

  plugin_specs = load_specs(File.join(plugin_gem_home, "specifications"))
  conflicts = plugin_specs.filter_map do |spec|
    core_versions = core_specs_by_name[spec.name]&.map { |core_spec| core_spec.version.to_s }&.uniq
    war_versions = war_versions_by_name[spec.name] || []
    next unless core_versions&.length == 1
    next if core_versions.include?(spec.version.to_s)
    next if war_versions.include?(spec.version.to_s)

    "#{spec.name}: plugin installed #{spec.version}, ArchivesSpace bundles #{core_versions.first}"
  end

  if conflicts.any?
    warn "Plugin installed versions that conflict with ArchivesSpace bundled gems:"
    conflicts.sort.each { |conflict| warn "\t#{conflict}" }
    FileUtils.rm_rf(plugin_gem_home)
    exit 1
  end
ensure
  FileUtils.rm_f(install_gemfile)
  FileUtils.rm_f("#{install_gemfile}.lock")
end
