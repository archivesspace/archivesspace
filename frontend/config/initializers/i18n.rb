module ActionView
  module Helpers
    module TranslationHelperDecorator
      private

      def html_safe_translation_key?(key)
        true
      end
    end
  end
end

ActionView::Helpers::TranslationHelper.prepend(ActionView::Helpers::TranslationHelperDecorator)


# TODO Remove
class JSONModelI18nWrapper < Hash
  def initialize(args)
    super
  end

  def enable_parse_mixed_content!(path = '/')
    true
  end
end
