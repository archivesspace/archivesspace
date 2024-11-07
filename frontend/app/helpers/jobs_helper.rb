module JobsHelper
  def file_label(job_type)
    if job_type == "print_to_pdf_job"
      I18n.t("actions.download_pdf")
    elsif job_type == "report_job"
      I18n.t("actions.download_report")
    elsif job_type == "bulk_import_job"
      I18n.t("actions.download_bulk_import_report")
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

  def is_global_record?(json_model)
    json_model.match?(/agent|location|subject/)
  end

  def link_for_resource(uri)
    id = JSONModel(:resource).id_for(uri)
    URI.join(
      AppConfig[:frontend_proxy_url], File.join('resources', id.to_s, "edit#tree::resource_#{id}")
    ).to_s
  end
end
