# Be sure to restart your server when you modify this file.

module Plugins

  def self.init
    @config = {'plugins' => []}
    Array(AppConfig[:plugins]).each do |plugin|
      if Dir.glob(Rails.root.join('..', 'plugins', plugin, 'frontend', 'controllers', '*_controller.rb')).length > 0
        @config['plugins'] << plugin
      end
    end
    puts "Found controllers for plug-ins: #{@config['plugins'].inspect}"
  end


  def self.list
    @config['plugins']
  end


  def self.plugins?
    @config['plugins'].length > 0
  end

end

Plugins::init
