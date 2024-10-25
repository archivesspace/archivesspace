include JSONModel

class NS2RemoverRunner < JobRunner
  register_for_job_type('ns2_remover_job',
                        :create_permissions => :administer_system,
                        :cancel_permissions => :administer_system)

  def run
    begin
      modified_records = []

      job_data = @json.job

      RequestContext.open(:repo_id => @job.repo_id) do
        count = 0
        Note.each do |n|
          parent = NotePersistentId.where(:note_id => n[:id]).first
          unless parent
            @job.write_output("Warning: Cannot find parent of Note with ID: #{n[:id]}")
            Log.warn("Cannot find parent of Note with ID: #{n[:id]}")

            next
          end

          next unless ['resource', 'archival_object', 'digital_object', 'digital_object_component'].include?(parent[:parent_type])
          if n.notes.lit.include?(' ns2:')
            replaced = n.notes.lit.gsub('ns2:', '')
            if replaced != n[:notes].lit
              count += 1
              parent_repo = parent[:parent_type].capitalize.constantize.where(id: parent[:parent_id]).get(:repo_id)
              if job_data['dry_run']
                changes = <<~CHANGES
                  Note:
                    #{n[:notes].lit}
                  would become:
                    #{replaced}\n
                CHANGES
                @job.write_output(changes)
              else
                n.update(:notes => replaced.to_sequel_blob)
              end
              if parent_repo == @job.repo_id
                modified_records << JSONModel(parent[:parent_type].to_sym).uri_for(parent[:parent_id], :repo_id => @job.repo_id)
              else
                modified_records << JSONModel(parent[:parent_type].to_sym).uri_for(parent[:parent_id], :repo_id => parent_repo)
              end
            end
          end
        end

        @job.write_output("#{count} note(s)#{' would be' if job_data['dry_run']} modified.")
        @job.write_output("================================")
      end

      if job_data['dry_run']
        @job.write_output("Dry run complete, no records modified.")
      elsif modified_records.empty?
        @job.write_output("All done, no records modified.")
      else
        @job.write_output("All done, logging modified records.")
      end

      self.success!

      @job.record_created_uris(modified_records.uniq) unless job_data['dry_run']
    rescue Exception => e
      @job.write_output(e.message)
      @job.write_output(e.backtrace)
      raise e
    end
  end
end
