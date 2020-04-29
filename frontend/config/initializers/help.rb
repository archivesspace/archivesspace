# Be sure to restart your server when you modify this file.

require 'yaml'

module ArchivesSpaceHelp
  def self.init
    load_help_config_file
  end

  def self.[](key)
    @config["topics"][key]
  end

  def self.enabled?
    AppConfig[:help_enabled] === true
  end

  def self.base_url
    raise "No AppConfig[:help_url] defined" if AppConfig[:help_url].blank?

    AppConfig[:help_url]
  end

  def self.url_for_topic(topic)
    if self[topic]
      return "#{AppConfig[:help_topic_base_url]}#{self[topic]}"
    end
  end

  def self.topic?(key)
    @config["topics"].has_key? key
  end

  def self.load_help_config_file
    @config = YAML.load_file(Rails.root.join('config', 'help.yml'))
  end
end

ArchivesSpaceHelp::init
