#!/usr/bin/env ruby
# Splits the frontend (SUI) feature specs into CI shards that take about the same time to run.
#
# How CI keeps the shards balanced (.github/workflows/frontend.yml):
#   1. Every shard job records the run time of each spec file it runs (file_timing_formatter.rb).
#   2. After the shard jobs, `merge-timings` merges those timings into the ones of previous runs,
#      which are kept in the GitHub Actions cache.
#   3. The next run balances the spec files over the shards with `matrix`, using the cached timings.
# So changed spec files are re-timed on every run, and new spec files are placed with the median
# time on their first run and with their measured time from then on.
#
# Caches are scoped to branches: a pull request uses its own earlier runs' timings, or else those of
# the default branch. frontend_feature_timings.yml keeps the default branch's timings up to date by
# running the feature specs there whenever files in the frontend path filter
# (.github/path-filters.yml) change.
#
# frontend/spec/feature_shards.yml is the checked in baseline: it sets the number of shards and
# holds the timings used when no cached timings are available (e.g. when the cache has expired).
#
# Commands (run from anywhere in the repository). TIMINGS files are either JSON lines written by
# file_timing_formatter.rb or JSON objects of spec file => seconds written by merge-timings.
#
#   time [-o TIMINGS] [PATTERN] [-Dproperty=value...]
#     Runs the feature specs (default pattern: spec/features/*_spec.rb) through
#     `./build/run frontend:test` and records the run time of each spec file as JSON lines
#     in TIMINGS (default: build/frontend_feature_timings.jsonl). Needs the test database and
#     Solr running, as for any frontend:test run, and nothing else using them meanwhile:
#     other test runs reset the database. -D arguments are passed on to ant, e.g. to point
#     the run at a separate database (with the ASPACE_TEST_DB_URL and ASPACE_TEST_SOLR_URL
#     environment variables): -Daspace.db_port.test=3317
#
#   generate [-n SHARDS] [TIMINGS...]
#     Rewrites the baseline shards file, balancing the spec files into SHARDS shards (default:
#     the current number of shards, or 10). The timings of the current shards file are
#     updated with each TIMINGS file in turn, so a subset of the specs can be re-timed and
#     merged in. The timings CI gathered can be used too: download the feature-spec-timings
#     artifact of a frontend workflow run with `gh run download RUN_ID -n feature-spec-timings`.
#
#   matrix [--timings TIMINGS]
#     Prints the GitHub Actions matrix as JSON: [{"shard":1,"pattern":"..."}, ...], balancing the
#     spec files over the baseline's number of shards with the baseline timings updated with
#     TIMINGS (skipped if the file does not exist).
#
#   merge-timings --out OUT [TIMINGS...]
#     Merges TIMINGS files in turn (missing files are skipped), keeps the spec files that still
#     exist and writes them to OUT as a JSON object of spec file => seconds.
#
# Spec files without a timing are given the median time.

require 'json'
require 'optparse'
require 'yaml'

ROOT = File.expand_path('../..', __dir__)
FRONTEND = File.join(ROOT, 'frontend')
SHARDS_FILE = File.join(FRONTEND, 'spec', 'feature_shards.yml')
FEATURE_GLOB = 'spec/features/*_spec.rb'
DEFAULT_SHARD_COUNT = 10

def feature_files
  Dir.chdir(FRONTEND) { Dir.glob(FEATURE_GLOB).sort }
end

def load_shards
  return [] unless File.exist?(SHARDS_FILE)

  YAML.safe_load(File.read(SHARDS_FILE)).fetch('shards').map { |shard| shard.fetch('files') }
end

def load_timings(path)
  return JSON.parse(File.read(path)) if path.end_with?('.json')

  # Sums the timings of each file's top level groups per rspec run and keeps the last run of each file
  runs = Hash.new { |hash, file| hash[file] = {} }
  File.foreach(path) do |line|
    next if line.strip.empty?

    entry = JSON.parse(line)
    runs[entry['file']][entry['run']] = runs[entry['file']].fetch(entry['run'], 0) + entry['seconds']
  end
  runs.transform_values { |seconds_by_run| seconds_by_run.values.last }
end

# Timings of the given files, later ones replacing earlier ones, skipping files that do not exist
def merge_timings(paths, timings = {})
  paths.each_with_object(timings.dup) do |path, merged|
    if File.exist?(path)
      merged.merge!(load_timings(path))
    else
      warn "Skipping #{path}: not found"
    end
  end
end

def median(values)
  sorted = values.sort
  (sorted[(sorted.size - 1) / 2] + sorted[sorted.size / 2]) / 2.0
end

def warn_github(message)
  warn(ENV['GITHUB_ACTIONS'] ? "::warning::#{message}" : "warning: #{message}")
end

# Returns [{file => seconds}, ...] per shard, giving files without a timing the median time
def balance(timings, shard_count)
  files = feature_files
  timings = timings.slice(*files)
  abort 'No timings found for any feature spec file' if timings.empty?

  default_seconds = median(timings.values)
  (files - timings.keys).each do |file|
    warn_github("No timing for #{file} yet, assuming the median of #{default_seconds.round(2)}s")
    timings[file] = default_seconds
  end

  # Longest processing time first: give each file, slowest first, to the shard with the least time so far
  shards = Array.new(shard_count) { {} }
  timings.sort_by { |file, seconds| [-seconds, file] }.each do |file, seconds|
    shards.min_by { |shard| shard.values.sum }[file] = seconds
  end
  shards.map { |shard| shard.sort.to_h }
end

def time_specs(args)
  out = File.join(ROOT, 'build', 'frontend_feature_timings.jsonl')
  ant_args, args = args.partition { |arg| arg.start_with?('-D') }
  OptionParser.new { |opts| opts.on('-o', '--out TIMINGS') { |value| out = File.expand_path(value) } }.parse!(args)
  pattern = args.first || FEATURE_GLOB

  formatter = File.join(__dir__, 'frontend_feature_shards', 'file_timing_formatter.rb')
  # Formatters given in SPEC_OPTS replace the ones on the rspec command line, so keep documentation output too
  spec_opts = "--require #{formatter} --format documentation --format FileTimingFormatter --out #{out}"
  puts "Recording feature spec timings in #{out}"
  system({ 'SPEC_OPTS' => spec_opts }, File.join(ROOT, 'build', 'run'), 'frontend:test', "-Dpattern=#{pattern}", *ant_args, chdir: ROOT)
  abort "No timings were recorded in #{out}, see the output above" if File.size?(out).nil?

  puts "Timings recorded in #{out}; spec failures do not affect them. Next run:"
  puts "  ruby #{File.join('build', 'scripts', File.basename(__FILE__))} generate #{out}"
end

def generate(args)
  shard_count = nil
  OptionParser.new { |opts| opts.on('-n', '--shards SHARDS', Integer) { |value| shard_count = value } }.parse!(args)

  current_shards = load_shards
  shard_count ||= current_shards.empty? ? DEFAULT_SHARD_COUNT : current_shards.size
  shards = balance(merge_timings(args, current_shards.reduce({}, :merge)), shard_count)

  write_shards(shards)
  shards.each_with_index do |shard, index|
    puts format('Shard %2d: %3d files, %6.0fs', index + 1, shard.size, shard.values.sum)
  end
end

def write_shards(shards)
  yaml = +<<~HEADER
    # Frontend (SUI) feature spec shards for CI, balanced by the run time of each spec file.
    #
    # This is the baseline for .github/workflows/frontend.yml: it sets the number of shards, and CI
    # balances the spec files with these timings, updated with the timings of previous CI runs.
    # CI keeps those up to date by itself; this file only needs regenerating to change the number
    # of shards, or to refresh the timings used when no previous CI timings are cached.
    #
    # Generated by build/scripts/frontend_feature_shards.rb; do not edit by hand. To regenerate
    # from the timings of a frontend workflow run (add -n SHARDS to change the number of shards):
    #   gh run download RUN_ID -n feature-spec-timings
    #   ruby build/scripts/frontend_feature_shards.rb generate feature_timings.json
    shards:
  HEADER
  shards.each do |shard|
    yaml << "  - estimated_seconds: #{shard.values.sum.round}\n"
    yaml << "    files:\n"
    shard.each { |file, seconds| yaml << "      #{file}: #{seconds.round(2)}\n" }
  end
  File.write(SHARDS_FILE, yaml)
  puts "Wrote #{SHARDS_FILE.delete_prefix("#{ROOT}/")}"
end

def matrix(args)
  timings_paths = []
  OptionParser.new { |opts| opts.on('--timings TIMINGS') { |value| timings_paths << value } }.parse!(args)

  baseline = load_shards
  abort "#{SHARDS_FILE} not found or has no shards" if baseline.empty?

  shards = balance(merge_timings(timings_paths, baseline.reduce({}, :merge)), baseline.size)
  shards.each_with_index do |shard, index|
    warn format('Shard %2d: %3d files, %6.0fs estimated', index + 1, shard.size, shard.values.sum)
  end

  puts shards.each_with_index
             .reject { |shard, _| shard.empty? }
             .map { |shard, index| { shard: index + 1, pattern: shard.keys.join(',') } }
             .to_json
end

def merge_timings_command(args)
  out = nil
  OptionParser.new { |opts| opts.on('-o', '--out OUT') { |value| out = value } }.parse!(args)
  abort 'merge-timings needs --out OUT' unless out

  timings = merge_timings(args).slice(*feature_files).sort.to_h.transform_values { |seconds| seconds.round(2) }
  File.write(out, "#{JSON.pretty_generate(timings)}\n")
  puts "Wrote timings of #{timings.size} spec files to #{out}"
end

command = ARGV.shift
case command
when 'time' then time_specs(ARGV)
when 'generate' then generate(ARGV)
when 'matrix' then matrix(ARGV)
when 'merge-timings' then merge_timings_command(ARGV)
else
  abort "Usage: #{File.basename(__FILE__)} time [-o TIMINGS] [PATTERN] [-Dproperty=value...] | " \
        'generate [-n SHARDS] [TIMINGS...] | matrix [--timings TIMINGS] | merge-timings --out OUT [TIMINGS...]'
end
