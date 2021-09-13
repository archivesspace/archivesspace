class GenerateArksRunner < JobRunner
  register_for_job_type('generate_arks_job',
                        {:create_permissions => :administer_system,
                         :cancel_permissions => :administer_system})

  def underlined_msg(s)
    @job.write_output("#{s}\n#{'=' * s.length}")
  end


  def run
    DB.open do
      ArkName.run_housekeeping!
    end

    Repository.each do |repo|
      RequestContext.open(:repo_id => repo.id) do
        ASModel.all_models.select {|model| model.included_modules.include?(Arks)}.each do |model|

          underlined_msg("Repository #{repo.repo_code}: Generating ARKs for #{model} records")

          created_arks = 0
          model.this_repo.each_slice(512) do |objs|
            DB.open do
              fk = ArkName.fk_for_class(model)

              # Retain any existing external URL values
              user_value_lookup = ArkName.filter(fk => objs.map(&:id),
                                                 :is_current => 1)
                                    .select(fk, :user_value)
                                    .map {|row| [row[fk], row[:user_value]] }
                                    .to_h

              records_to_reindex = []
              objs.each do |obj|
                begin
                  if ArkName.ensure_ark_for_record(obj, user_value_lookup.fetch(obj.id, nil))
                    created_arks += 1
                    records_to_reindex << obj.id
                  end
                rescue => e
                  @job.write_output(" -> Error generating ARK for #{model} #{obj.id} => #{e.message}")
                end
              end

              model.update_mtime_for_ids(records_to_reindex)
            end
          end

          if created_arks == 0
            underlined_msg("Repository #{repo.repo_code}: ARKs for #{model} records were already up-to-date")
          else
            underlined_msg("Repository #{repo.repo_code}: Generated #{created_arks} ARKs for #{model} records")
          end
        end
      end
    end
  rescue
    @job.write_output("Caught an error during run: #{$!}")
    Log.error($!)

    raise $!
  end
end
