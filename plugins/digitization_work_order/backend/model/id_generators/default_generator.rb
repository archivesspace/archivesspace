class DefaultGenerator < GeneratorInterface

  PREFIX = 'cuid'

  def generate(record)
    PREFIX + Sequence.get("/repositories/#{record.repo_id}/archival_objects/component_id_for_work_order").to_s
  end

end
