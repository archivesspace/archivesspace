require_relative 'user'

class FindAndReplaceJob < Sequel::Model(:find_and_replace_job)
  include ASModel
  corresponds_to JSONModel(:find_and_replace_job)

  many_to_one :owner, :key => :owner_id, :class => User

  set_model_scope :repository


  def self.create_from_json(json, opts = {})
    super(json, opts.merge(:time_submitted => Time.now,
                           :owner_id => opts.fetch(:user).id,
                           :arguments => ASUtils.to_json(json.arguments),
                           :scope => ASUtils.to_json(json.scope)))
  end


  def finish(status)

    self.reload
    self.status = "#{status}"
    self.time_finished = Time.now
    self.save
  end

end
