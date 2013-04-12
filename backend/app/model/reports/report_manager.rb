module ReportManager
  @@registered_reports ||= {}


  def self.register_report(report_class, opts)
    opts[:model] = report_class
    opts[:params] ||= []

    opts[:uri_suffix] ||= report_class.name.downcase

    Log.warn("Report with uri '#{opts[:uri_suffix]}' already registered") if @@registered_reports.has_key?(opts[:uri_suffix])

    @@registered_reports[opts[:uri_suffix]] = opts
  end


  def self.registered_reports
    @@registered_reports
  end


  module Mixin

    def self.included(base)
      base.extend(ClassMethods)
    end


    module ClassMethods

      def register_report(opts)
        ReportManager.register_report(self, opts)
      end

    end
  end
end