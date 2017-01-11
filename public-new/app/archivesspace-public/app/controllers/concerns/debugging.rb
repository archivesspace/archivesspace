module Debugging
  extend ActiveSupport::Concern
  require 'pry'

  # Pretty Print
  def dbgpp(text, obj = nil)
    if %w|development test|.include? Rails.env
      Rails.logger.debug(text)
      Pry::ColorPrinter.pp(obj) if obj
    end
  end
end
