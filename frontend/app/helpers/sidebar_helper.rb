module SidebarHelper

  class SidebarGenerator

    def initialize(form, opts)
      ensure_properties(opts, [:record, :record_type])

      @form = form
      @opts = opts
    end


    def ensure_properties(opts, properties)
      properties.each do |p|
        raise "Missing required property: #{p}" if !opts[p]
      end
    end


    def render_for_view_and_edit(opts)
      ensure_properties(opts, [:subrecord_type, :property])

      record = @opts[:record]
      property = opts[:property]

      if @form.controller.action_name != "show" || property == :none || !record[property].blank?
        render_entry(opts)
      end
    end


    def render_for_view_only(opts)
      ensure_properties(opts, [:subrecord_type, :property])

      record = @opts[:record]
      property = opts[:property]

      if @form.controller.action_name == "show" && (!record[property].blank? || property == :none)
        render_entry(opts)
      end
    end


    def show_external_ids_sidebar_entry?
      record = @opts[:record]

      @form.controller.action_name == 'show' ||
        @form.controller.action_name != 'show' && !ASUtils.wrap(record['external_ids']).empty?
    end


    private

    def render_entry(opts)
      @form.render_aspace_partial(:partial => '/shared/sidebar_entry',
                   :locals => opts.merge(@opts))
    end

  end

end
