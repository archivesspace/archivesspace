class JobCreatedRecord < Sequel::Model(:job_created_record)
  include ASModel

  set_model_scope :global


  def self.sequel_to_jsonmodel(objs, opts = {})
    objs.map {|obj|
      {'record' => {'ref' => obj.record_uri}}
    }
  end
end
