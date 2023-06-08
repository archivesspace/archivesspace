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

class EnumerationMigrationFailed < StandardError
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
    if property.is_a? Hash
      @conflicts[uri] ||= []
      @conflicts[uri] << property
    else
      @conflicts[uri] = property
    end
  end

  def to_s
    "#<#{self.class}: #{@conflicts.inspect}>"
  end
end


class RepositoryNotEmpty < StandardError
end


class ImportCanceled < StandardError
  def to_s
    "The import was canceled"
  end
end

class ImportException < StandardError
  attr_accessor :invalid_object
  attr_accessor :message
  attr_accessor :error

  def initialize(opts)
    @invalid_object = opts[:invalid_object]
    @error = opts[:error]
  end

  def to_hash
    hsh = {'record_title' => nil, 'record_type' => nil, 'error_class' => self.class.name, 'errors' => []}
    hsh['record_title'] = @invalid_object[:title] ? @invalid_object[:title] : "unknown or untitled"
    hsh['record_type'] = @invalid_object.jsonmodel_type ? @invalid_object.jsonmodel_type : "unknown type"

    if @error.respond_to?(:errors)
      @error.errors.each {|e| hsh['errors'] << e}
    else
      hsh['errors'] = @error.inspect
    end
    hsh
  end

  def to_s
    "#<:ImportException: #{{:invalid_object => @invalid_object, :error => @error}.inspect}>"
  end
end

class NotAllowed < StandardError
end


module Exceptions

  module ResponseMappings

    def self.included(base)
      base.instance_eval do

        error ImportException do
          json_response({:error => request.env['sinatra.error'].to_hash}, 400)
        end

        error RepositoryNotEmpty do
          json_response({:error => "Repository not empty"}, 409)
        end

        error Sinatra::NotFound do
          json_response({:error => request.env['sinatra.error']}, 404)
        end

        error NotFoundException do
          json_response({:error => request.env['sinatra.error']}, 404)
        end

        error BadParamsException do
          json_response({:error => request.env['sinatra.error'].params}, 400)
        end

        error ReadOnlyException do
          json_response({:error => request.env['sinatra.error']}, 409)
        end

        error UserNotFoundException do
          json_response({:error => {"member_usernames" => [request.env['sinatra.error']]}}, 400)
        end

        error BatchDeleteFailed do
          Log.exception(request.env['sinatra.error'])
          json_response({:error => {"failures" => request.env['sinatra.error'].errors}}, 403)
        end

        error TransferConstraintError do
          Log.exception(request.env['sinatra.error'])
          json_response({:error => request.env['sinatra.error'].conflicts}, 409)
        end

        error JSONModel::ValidationException do
          json_response({
                          :error => request.env['sinatra.error'].errors,
                          :warning => request.env['sinatra.error'].warnings,
                          :invalid_object => request.env['sinatra.error'].invalid_object.inspect
                        }, 400)
        end

        error ConflictException do
          json_response({:error => request.env['sinatra.error'].conflicts}, 409)
        end

        error AccessDeniedException do
          json_response({:error => "Access denied"}, 403)
        end

        error InvalidUsernameException do
          json_response({:error => "Invalid username"}, 400)
        end

        error Sequel::ValidationFailed do
          json_response({:error => request.env['sinatra.error'].errors}, 400)
        end

        error ReferenceError do
          Log.exception(request.env['sinatra.error'])
          json_response({:error => request.env['sinatra.error']}, 400)
        end

        error MergeRequestFailed do
          Log.exception(request.env['sinatra.error'])
          json_response({:error => request.env['sinatra.error']}, 400)
        end

        error EnumerationMigrationFailed do
          Log.exception(request.env['sinatra.error'])
          json_response({:error => request.env['sinatra.error']}, 400)
        end

        error Sequel::DatabaseError do
          Log.exception(request.env['sinatra.error'])
          json_response({:error => {:db_error => ["Database integrity constraint conflict: #{request.env['sinatra.error']}"]}}, 400)
        end

        error Sequel::Plugins::OptimisticLocking::Error do
          json_response({:error => "The record you tried to update has been modified since you fetched it."}, 409)
        end

        error JSON::ParserError do
          Log.exception(request.env['sinatra.error'])
          json_response({:error => "Had some trouble parsing your request: #{request.env['sinatra.error']}"}, 400)
        end

        error NotAllowed do
          json_response({:error => request.env['sinatra.error']}, 400)
        end

        error UserMailer::MailError do
          json_response({:error => request.env['sinatra.error']}, 400)
        end


        # Overriding Sinatra's default behaviour here
        define_method(:handle_exception!) do |ex|
          @env['sinatra.error'] = ex
          status ex.respond_to?(:code) ? Integer(ex.code) : 500

          if not_found?
            headers['X-Cascade'] = 'pass'
            body '<h1>Not Found</h1>'
            return
          end

          res = error_block!(ex.class, ex) || error_block!(status, ex)

          if res
            # One of our custom error handlers has saved the day
            res
          else
            Log.error('Unhandled exception!')
            Log.exception(request.env['sinatra.error'])

            message = ex.message + ": " + ex.backtrace.join("\n\t")

            json_response({:error => message}, 500)
          end
        end
      end
    end

  end

end
