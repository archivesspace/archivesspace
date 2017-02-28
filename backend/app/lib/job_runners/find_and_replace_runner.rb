class FindAndReplaceRunner < JobRunner

  def self.instance_for(job)
    if job.job_type == "find_and_replace_job"
      self.new(job)
    else
      nil
    end
  end


  def run
    super

    job_data = @json.job

    terminal_error = nil

    parsed = JSONModel.parse_reference(job_data['base_record_uri'])
    base_model = Kernel.const_get(parsed[:type].camelize)
    base_record = base_model.any_repo[parsed[:id]]

    target_model = case job_data['record_type']
                   when 'date'
                     ASDate
                   else
                     Kernel.const_get(job_data['record_type'].camelize)
                   end

    target_property = job_data['property']
    target_ids = base_record.object_graph.ids_for(target_model)

    find = job_data['find'] =~ /^\/.+\/$/ ? Regexp.new(job_data['find'][1..-2]) : job_data['find']
    replace = job_data['replace']

    modified_records = []

    begin
      DB.open(DB.supports_mvcc?,
              :retry_on_optimistic_locking_fail => true) do

        begin

          target_ids.each do |id|

            RequestContext.open(:current_username => @job.owner.username,
                                :repo_id => @job.repo_id) do
              json = target_model.to_jsonmodel(id)

              next unless json[target_property]
              result = json[target_property].gsub!(find, replace)

              next if result.nil?

              @job.write_output("Updating #{target_model.to_s}[#{id}].#{target_property}")

              target_model[id].update_from_json(json)

              if json.uri
                modified_records << json.uri
              else
                # it would be nice to capture
                # '/#' urls for nested records
                # and be able to resolve them
                # but that would require a rethink

                nested_model = target_model[id][:instance_id] ? Instance : target_model

                [:resource_id, :archival_object_id].each do |col|
                  nesting_id = nested_model[id][col]
                  if nesting_id
                    nesting_model = Kernel.const_get(col.to_s[0..-4].camelize)
                    modified_records << nesting_model[nesting_id].uri
                    break
                  end
                end
              end

            end

          end

          if modified_records.empty?
            @job.write_output("All done, no records modified.")
          else
            @job.write_output("All done, logging modified records.")
          end

          self.success!

          # just reuse JobCreated api for now...
          @job.record_created_uris(modified_records.uniq)
        rescue Exception => e
          terminal_error = e
          raise Sequel::Rollback
        end

      end

    rescue
      terminal_error = $!
    end

    if terminal_error
      @job.write_output(terminal_error.message)
      @job.write_output(terminal_error.backtrace)

      raise terminal_error
    end

  end
end
