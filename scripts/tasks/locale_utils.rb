# frozen_string_literal: true

# Main entry point for LocaleUtils module
# Requires all class files in dependency order

require_relative '../../common/locale_utils/line_info'
require_relative '../../common/locale_utils/locale_entry'
require_relative '../../common/locale_utils/locale_file'
require_relative '../../common/locale_utils/replacement'
require_relative '../../common/locale_utils/variable_replacer'
require_relative '../../common/locale_utils/malformed_variable_fixer'
require_relative '../../common/locale_utils/locale_variables'
require_relative '../../common/locale_utils/yaml_validator'
