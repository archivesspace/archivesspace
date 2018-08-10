module ReportManager

  @@registered_reports ||= {}

  ALLOWED_REPORT_FORMATS = ["json", "csv", "html", "pdf", "rtf"]

  def self.allowed_report_formats
    ALLOWED_REPORT_FORMATS
  end

  def self.register_report(report_class, opts)
    opts[:code] = report_class.code
    opts[:model] = report_class
    opts[:params] ||= []

    Log.warn("Report with code '#{opts[:code]}' already registered") if @@registered_reports.has_key?(opts[:code])

    @@registered_reports[opts[:code]] = opts
  end


  def self.registered_reports
    @@registered_reports
  end


  module Mixin

    def self.included(base)
      base.extend(ClassMethods)
    end


    module ClassMethods

      def register_report(opts = {})
        ReportManager.register_report(self, opts)
      end

    end
  end
end