# Be sure to restart your server when you modify this file.
require 'asutils'

module Plugins

  def self.init
    @config = {:system_menu_items => [], :repository_menu_items => [], :plugin => {}, :parents => {}}
    Array(AppConfig[:plugins]).each do |plugin|
      # config.yml is optional, so defaults go here
      @config[:plugin][plugin] = {'parents' => []}
      plugin_dir = ASUtils.find_local_directories(nil, plugin).shift

      config_path = File.join(plugin_dir, 'config.yml')
      if File.exist?(config_path)
        @config[:plugin][plugin] = cfg = YAML.load_file config_path
        @config[:system_menu_items] << cfg['system_menu_controller'] if cfg['system_menu_controller']
        @config[:repository_menu_items] << cfg['repository_menu_controller'] if cfg['repository_menu_controller']
        (cfg['parents'] || {}).keys.each do |parent|
          @config[:parents][parent] ||= []
          @config[:parents][parent] << plugin
        end
      end
    end

    if @config[:system_menu_items].length > 0
      puts "Found system menu items for plug-ins: #{system_menu_items.inspect}"
    end

    if @config[:repository_menu_items].length > 0
      puts "Found repository menu items for plug-ins: #{repository_menu_items.inspect}"
    end

    @sections = []
  end


  def self.system_menu_items
    Array(@config[:system_menu_items]).flatten
  end


  def self.system_menu_items?
    system_menu_items.length > 0
  end


  def self.repository_menu_items
    Array(@config[:repository_menu_items]).flatten
  end


  def self.repository_menu_items?
    repository_menu_items.length > 0
  end


  def self.config_for(plugin)
    @config[:plugin][plugin] || {}
  end


  def self.parent_for(plugin, parent)
    @config[:plugin][plugin]['parents'][parent]
  end


  def self.plugins_for(parent)
    @config[:parents][parent] || []
  end


  def self.register_plugin_section(plugin_section)
    @sections << plugin_section
  end

  def self.sections_for(record, mode)
    @sections.select{|plugin_section| plugin_section.supports?(record, mode)}
  end


  class AbstractPluginSection
    def initialize(plugin, name, jsonmodel_types, opts = {})
      @plugin = plugin
      @name = name
      @jsonmodel_types = ASUtils.wrap(jsonmodel_types)

      parse_opts(opts)
    end

    def render_edit(view_context, record, form_context)
      raise "IMPLEMENT ME"
    end

    def render_readonly(view_context, record, form_context)
      raise "IMPLEMENT ME"
    end

    def render_sidebar(view_context, record, mode)
      "<li>" +
        "  <a href='##{build_section_id(record['jsonmodel_type'])}'>" +
        "    #{@sidebar_label}" +
        "    <span class='glyphicon glyphicon-chevron-right'></span>" +
        "  </a>" +
        "</li>".html_safe
    end

    def supports?(record, mode)
      @jsonmodel_types.include?(record['jsonmodel_type']) &&
        (mode == :edit && @show_on_edit ||
          mode == :readonly && @show_on_readonly)
    end

    private

    def parse_opts(opts)
      @show_on_edit = opts.fetch(:show_on_edit, true)
      @show_on_readonly = opts.fetch(:show_on_readonly, true)
      @section_id = opts.fetch(:section_id, nil)
      @sidebar_label = opts.fetch(:sidebar_label, I18n.t("plugins.#{@plugin}.#{@name}.section"))
    end

    def build_section_id(jsonmodel_type)
      @section_id ? @section_id : "#{jsonmodel_type}_#{@name}"
    end
  end


  class PluginSubRecord < AbstractPluginSection

    def render_edit(view_context, record, form_context)
      view_context.render_aspace_partial(
        :partial => "shared/subrecord_form",
        :locals => {
          :form => form_context,
          :name => @jsonmodel_field,
          :cardinality => @cardinality,
          :template => @template_name,
          :template_erb => @erb_edit_template_path,
          :js_template_name => @js_edit_template_name,
          :section_id => build_section_id(form_context.obj['jsonmodel_type']),
        })
    end

    def render_readonly(view_context, record, form_context)
      view_context.render_aspace_partial(
        :partial => @erb_readonly_template_path,
        :locals => { @jsonmodel_field.intern => record.send(@jsonmodel_field.intern),
                     :context => form_context,
                     :section_id => build_section_id(form_context.obj['jsonmodel_type']) })
    end

    def supports?(record, mode)
      result = super
      if result && mode == :readonly
        Array(record.send(@jsonmodel_field.intern)).length > 0
      else
        result
      end
    end

    private

    def parse_opts(opts)
      super

      @jsonmodel_field = opts.fetch(:jsonmodel_field, @name)
      @cardinality = opts.fetch(:cardinality, :zero_to_many)
      @template_name = opts.fetch(:template_name, @name)
      @erb_edit_template_path = opts.fetch(:erb_edit_template_path, "#{@name}/template")
      @js_edit_template_name = opts.fetch(:js_edit_template_name, "template_#{@name}")
      @erb_readonly_template_path = opts.fetch(:erb_readonly_template_path, "#{@name}/show_as_subrecords")
    end
  end


  class PluginReadonlySearch < AbstractPluginSection

    def render_readonly(view_context, record, form_context)
      view_context.render_aspace_partial(
        :partial => "search/embedded",
        :locals => {
          :record => record,
          :filter_term => @filter_term_proc.call(record),
          :heading_text => @heading_text,
          :section_id => @section_id ? @section_id : build_section_id(form_context.obj['jsonmodel_type']),
        }
      )
    end

    private

    def parse_opts(opts)
      super

      @show_on_edit = false
      @filter_term_proc = opts.fetch(:filter_term_proc)
      @heading_text = opts.fetch(:heading_text)
    end

  end
end

Plugins::init
