module ReportManager
  @@registered_reports ||= {}


  def self.register_report(report_class, opts)
    opts[:model] = report_class
    opts[:params] ||= []
    @@registered_reports[report_class] = opts
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