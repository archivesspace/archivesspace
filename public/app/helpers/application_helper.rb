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
  # @param position [Symbol] :top (default) or :bottom
  def render_pagination(pager, position: :top)
    render partial: 'shared/pagination', locals: { pager: pager, position: position }
  end
end
