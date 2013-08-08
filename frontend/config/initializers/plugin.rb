# Be sure to restart your server when you modify this file.
require 'asutils'

module Plugins

  def self.init
    @config = {:system_menu_items => [], :repository_menu_items => [], :plugin => {}, :parents => {}}
    Array(AppConfig[:plugins]).each do |plugin|
      # config.yml is optional, so defaults go here
      @config[:plugin][plugin] = {'parents' => []}
      plugin_dir = ASUtils.find_local_directories(nil, plugin).shift
      Dir.glob(File.join(plugin_dir, 'config.yml')).each do |config|
        @config[:plugin][plugin] = cfg = YAML.load_file File.absolute_path(config)
        @config[:system_menu_items] << cfg['system_menu_controller'] if cfg['system_menu_controller']
        @config[:repository_menu_items] << cfg['repository_menu_controller'] if cfg['repository_menu_controller']
        (cfg['parents'] || {}).keys.each do |parent|
          @config[:parents][parent] ||= []
          @config[:parents][parent] << plugin
        end
      end
    end

    if @config[:system_menu_items].length > 0
      puts "Found system menu items for plug-ins: #{@config[:system_menu_items].inspect}"
    end

    if @config[:repository_menu_items].length > 0
      puts "Found repository menu items for plug-ins: #{@config[:repository_menu_items].inspect}"
    end
  end


  def self.system_menu_items
    @config[:system_menu_items]
  end


  def self.system_menu_items?
    @config[:system_menu_items].length > 0
  end


  def self.repository_menu_items
    @config[:repository_menu_items]
  end


  def self.repository_menu_items?
    @config[:repository_menu_items].length > 0
  end


  def self.config_for(plugin)
    @config[:plugin][plugin]
  end


  def self.parent_for(plugin, parent)
    @config[:plugin][plugin]['parents'][parent]
  end


  def self.plugins_for(parent)
    @config[:parents][parent] || []
  end

end

Plugins::init
