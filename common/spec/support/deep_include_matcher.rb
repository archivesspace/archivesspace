RSpec::Matchers.define :deep_include do |expected|
  match do |actual|
    deep_include?(actual, expected)
  end

  failure_message do |actual|
    "expected:\n #{actual} \nto deep-include:\n #{expected}"
  end

  def deep_include?(actual, expected)
    case expected
    when Hash
      return false unless actual.is_a?(Hash)
      expected.all? do |k, v|
        actual.key?(k) && deep_include?(actual[k], v)
      end
    when Array
      return false unless actual.is_a?(Array)
      expected.all? do |expected_elem|
        actual.any? { |actual_elem| deep_include?(actual_elem, expected_elem) }
      end
    else
      actual == expected
    end
  end
end
