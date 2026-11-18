# frozen_string_literal: true

require 'json'

# Splits the feature files across CI shards so that every shard takes about as long,
# by the feature durations recorded from earlier runs.
module ShardPlanner
  DURATIONS_FILE = File.expand_path('../feature_durations.json', __dir__)
  FEATURE_GLOBS = ['staff_features/**/*.feature', 'pui_features/**/*.feature'].freeze
  SCENARIO_LINE = /^\s*Scenario( Outline| Template)?:/

  module_function

  def feature_paths(root)
    FEATURE_GLOBS.flat_map { |glob| Dir.glob(glob, base: root) }.sort
  end

  # Longest feature first onto the least loaded shard
  def shard(root, total, index, durations = load_durations)
    paths = feature_paths(root)
    average = average_scenario_seconds(root, durations.slice(*paths))
    # a feature without a recorded duration is estimated from its scenario count
    seconds = paths.to_h { |path| [path, durations.fetch(path) { scenario_count(root, path) * average }] }

    shards = Array.new(total) { [] }
    loads = Array.new(total, 0)
    paths.sort_by { |path| [-seconds[path], path] }.each do |path|
      lightest = loads.index(loads.min)
      shards[lightest] << path
      loads[lightest] += seconds[path]
    end

    shards.fetch(index - 1).sort
  end

  def average_scenario_seconds(root, durations)
    scenarios = durations.keys.sum { |path| scenario_count(root, path) }
    return 30 if scenarios.zero?

    durations.values.sum / scenarios.to_f
  end

  def scenario_count(root, path)
    File.foreach(File.join(root, path)).count { |line| line.match?(SCENARIO_LINE) }
  end

  def load_durations
    File.exist?(DURATIONS_FILE) ? JSON.parse(File.read(DURATIONS_FILE)) : {}
  end

  # From the cucumber JSON reports of one or more full runs, e.g. the e2e-results-shard-* CI artifacts;
  # a feature reported by several runs gets its average duration
  def record_durations(report_paths)
    totals = Hash.new(0.0)
    runs = Hash.new(0)

    report_paths.each do |report_path|
      JSON.parse(File.read(report_path)).each do |feature|
        runs[feature['uri']] += 1
        totals[feature['uri']] += feature_seconds(feature)
      end
    end

    durations = totals.sort.to_h { |path, total| [path, (total / runs[path]).round] }
    File.write(DURATIONS_FILE, "#{JSON.pretty_generate(durations)}\n")
  end

  def feature_seconds(feature)
    feature['elements'].to_a.sum do |element|
      results = element['steps'].to_a + element['before'].to_a + element['after'].to_a
      results.sum { |result| result.dig('result', 'duration').to_i } / 1e9
    end
  end
end
