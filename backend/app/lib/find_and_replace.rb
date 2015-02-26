

class FindAndReplaceRunner

  def initialize(job, canceled = false)
    @job = job
    @canceled = canceled
  end


  def run

    arguments = ASUtils.json_parse(@job.arguments)
    scope = ASUtils.json_parse(@job.scope)

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

          target_model[id].update_from_json(json)
        end

      rescue JSONModel::ValidationException => e

        raise Sequel::Rollback
      end

    end

  end

end
