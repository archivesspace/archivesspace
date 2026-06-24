class BulkImportTemplatesController < ApplicationController

  set_access_control "view_repository" => [:index, :download]

  TEMPLATE_FILES = [
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
    {
      :name => I18n.t('import_job.import_type_subject_csv'),
      :filename => "aspace_subject_import_template.csv"
    },
  ].sort_by { |template| template[:name] }

  def index
    @template_files = TEMPLATE_FILES
  end

  def download
    template = TEMPLATE_FILES.find { |t| t.fetch(:filename) == params['filename'] }
    if template
      send_file "#{Rails.root}/public/bulk_import_templates/#{template.fetch(:filename)}", status: 202
    else
      redirect_to(:controller => :bulk_import_templates, :action => :index)
    end
  end
end
