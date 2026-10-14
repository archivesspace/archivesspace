module ApplicationHelper
  include PrefixHelper
  include RequestsHelper

  def bootstrap_class_for flash_type
    { success: "alert-success", error: "alert-danger", alert: "alert-warning", notice: "alert-info" }[flash_type.to_sym] || flash_type.to_s
  end

  def flash_messages(opts = {})
    flash.each do |msg_type, message|
      concat(content_tag(:div, class: "alert #{bootstrap_class_for(msg_type)} alert-dismissible fade show", role: 'alert') do
        concat(message.is_a?(Array) ? message.join('<br/>').html_safe : message.html_safe)
        concat(content_tag(:button, '', class: 'btn-close', type: 'button', data: { 'bs-dismiss' => 'alert' }, 'aria-label' => 'Close'))
      end)
    end
    nil
  end

  # @param pager [Pager]
  # @param position [Symbol, nil] :top or :bottom to disambiguate dual pagination; omit for a single block
  # @param nav_class [String, nil] optional extra classes for the nav element
  def render_pagination(pager, position: nil, nav_class: nil)
    render partial: 'shared/pagination', locals: { pager: pager, position: position, nav_class: nav_class }
  end

  # Renders the InfiniteTree <template>s at most once per page, so pages with
  # several trees (eg classification search subgroups) don't duplicate ids.
  # @return [String, nil] the templates markup, or nil if already rendered
  def infinite_tree_templates
    return if @infinite_tree_templates_rendered

    @infinite_tree_templates_rendered = true
    render partial: 'shared/infinite_tree_templates'
  end
end
