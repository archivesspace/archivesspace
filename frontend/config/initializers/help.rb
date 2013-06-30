# Be sure to restart your server when you modify this file.

require 'yaml'

module ArchivesSpaceHelp
  def self.init
    load_help_config_file
  end

  def self.[](key)
    load_help_config_file
    @config["topics"][key]
  end

  def self.enabled?
    load_help_config_file
    @config["enabled"]
  end

  def self.base_url
    load_help_config_file
    @config["base_url"]
  end

  def self.topic_prefix
    load_help_config_file
    @config["topic_prefix"]
  end

  def self.url_for_topic(topic)
    load_help_config_file
    return "#{base_url}#{topic_prefix}#{self[topic]}" if self[topic]
  end

  def self.topic?(key)
    load_help_config_file
    @config["topics"].has_key? key
  end

  def self.load_help_config_file
    @config = YAML.load_file(Rails.root.join('config', 'help.yml'))
  end
end

ArchivesSpaceHelp::init