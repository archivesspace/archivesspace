module JobsHelper



  def file_label(job_type)
    if job_type == "print_to_pdf_job"
      I18n.t("actions.download_pdf")
    elsif job_type == "report_job" 
      I18n.t("actions.download_report")
    else
      "File"
    end
  end


  def badge_class_for_status(status)
    if status === "running"
      "badge badge-info"
    elsif status === "completed"
      "text-success"
    elsif status === "queued"
      "badge badge-warning"
    elsif status === "failed"
      "badge badge-important"
    elsif status === "canceled"
      "text-error"
    else
      ""
    end
  end

end
