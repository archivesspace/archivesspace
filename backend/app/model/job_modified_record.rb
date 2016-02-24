class JobModifiedRecord < Sequel::Model(:job_modified_record)
  include ASModel

  set_model_scope :global


  def self.sequel_to_jsonmodel(objs, opts = {})
    objs.map {|obj|
      {'record' => {'ref' => obj.record_uri}}
    }
  end
end
