# Be sure to restart your server when you modify this file.

require 'yaml'

module ArchivesSpaceHelp
  def self.init
    # Load ArchivesSpace Help config
    @config = YAML.load_file(Rails.root.join('config', 'help.yml'))
  end

  def self.[](key)
    @config["topics"][key]
  end

  def self.enabled?
    @config["enabled"]
  end

  def self.base_url
    @config["base_url"]
  end

  def self.url_for_topic(topic)
    return "#{base_url}#{self[topic]}" if self[topic]
  end

  def self.topic?(key)
    @config["topics"].has_key? key
  end
end

ArchivesSpaceHelp::init