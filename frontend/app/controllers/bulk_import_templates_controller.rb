class BulkImportTemplatesController < ApplicationController

  set_access_control "view_repository" => [:index, :download]

  def index
    @template_files = [
      {
        :name => I18n.t('import_job.import_type_accession_csv'),
        :filename => "aspace_accession_import_template.csv"
      },
      {
        :name => I18n.t('import_job.import_type_digital_object_csv'),
        :filename => "aspace_digital_object_import_template.csv"
      },
      {
        :name => I18n.t('import_job.bulk_import_csv'),
        :filename => "bulk_import_template.csv"
      },
      {
        :name => I18n.t('import_job.bulk_import_xlsx'),
        :filename => "bulk_import_template.xlsx"
      },
      {
        :name => I18n.t('import_job.bulk_import_DO_csv'),
        :filename => "bulk_import_DO_template.csv"
      },
      {
        :name => I18n.t('import_job.bulk_import_DO_xlsx'),
        :filename => "bulk_import_DO_template.xlsx"
      },
      {
        :name => I18n.t('import_job.import_type_location_csv'),
        :filename => "aspace_location_import_template.csv"
      },
      {
        :name => I18n.t('import_job.import_type_assessment_csv'),
        :filename => "aspace_assessment_import_template.csv"
      },
    ]
  end

  def download
    send_file "#{Rails.root}/docs/#{params['filename']}", status: 202
  end
end
