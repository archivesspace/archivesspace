module JobsHelper

  def badge_class_for_status(status)
    if status === "running"
      "badge badge-success"
    elsif status === "completed"
      "text-success"
    elsif status === "queued"
      "badge badge-warning"
    elsif status === "errored"
      "badge badge-important"
    elsif status === "canceled"
      "text-error"
    else
      ""
    end
  end

end