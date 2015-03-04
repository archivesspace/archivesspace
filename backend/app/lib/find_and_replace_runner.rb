require_relative 'job_runner'

class FindAndReplaceRunner < JobRunner

  def initialize(job)
    @job = job
    @json = Job.to_jsonmodel(job)
  end

  def self.instance_for(job)
    if job.job_type == "find_and_replace_job"
      self.new(job)
    else
      nil
    end
  end


  def run
    super

    arguments = @json.job['arguments']
    scope = @json.job['scope']

    parsed = JSONModel.parse_reference(scope['base_record_uri'])
    base_model = Kernel.const_get(parsed[:type].camelize)
    base_record = base_model.any_repo[parsed[:id]]

    target_model = Kernel.const_get(scope['jsonmodel_type'].camelize)
    target_property = scope['property']
    target_ids = base_record.object_graph.ids_for(target_model)

    find = arguments['find'] =~ /^\/.+\/$/ ? Regexp.new(arguments['find'][1..-2]) : arguments['find']
    replace = arguments['replace']


    DB.open(DB.supports_mvcc?,
            :retry_on_optimistic_locking_fail => true) do

      begin
        target_ids.each do |id|
          json = target_model.to_jsonmodel(id)

          next unless json[target_property]
          json[target_property].gsub!(find, replace)

          RequestContext.open(:current_username => @job.owner.username,
                              :repo_id => @job.repo_id) do
            target_model[id].update_from_json(json)
          end
        end

      rescue JSONModel::ValidationException => e

        raise Sequel::Rollback
      end

    end

  end

end
