# Be sure to restart your server when you modify this file.

module Plugins

  def self.init
    @config = {'plugins' => []}
    Dir.glob(Rails.root.join('..', 'plugins', '*', 'frontend', 'controllers', '*_controller.rb')).sort.each do |plugin|
      @config['plugins'] << plugin[/plugins#{File::SEPARATOR}(.+)#{File::SEPARATOR}frontend/, 1]
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
