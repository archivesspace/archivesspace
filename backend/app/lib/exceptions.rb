require "exceptions"

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


class UserNotFoundException < StandardError
end


class InvalidUsernameException < StandardError
end

class SequenceError < StandardError
end


class ReferenceError < StandardError
end


class RetryTransaction < Sequel::DatabaseError
end


class MergeRequestFailed < StandardError
end


class BatchDeleteFailed < StandardError
  attr_accessor :errors

  def initialize(errors)
    @errors = errors
  end
end


class TransferConstraintError < StandardError
  attr_accessor :conflicts

  def initialize(conflicts = {})
    @conflicts = conflicts
  end

  def add_conflict(uri, property)
    @conflicts[uri] = property
  end
end
