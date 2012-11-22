require_relative "../../../common/exceptions"

class BadParamsException < StandardError
  attr_accessor :params

  def initialize(params)
    @params = params
  end
end


class NotFoundException < StandardError
end


class ReadOnlyException < StandardError
end


class SequenceError < StandardError
end
