class DigitalObjectListTableReport < AbstractReport

  register_report

  def template
    'generic_listing.erb'
  end

  def headers
    ['title', 'identifier', 'objectType', 'dateExpression', 'resourceIdentifier']
  end

  def processor
    {
      'resourceIdentifier' => proc{|record| ASUtils.json_parse(record[:resourceIdentifier] || '[]').compact.join('.')}
    }
  end

  def query
    db[:digital_object].
      left_outer_join(:instance_do_link_rlshp,
           :instance_do_link_rlshp__digital_object_id => :digital_object__id).
      select(Sequel.as(:digital_object__id, :id),
             Sequel.as(:digital_object__repo_id, :repoId),
             Sequel.as(:digital_object__digital_object_id, :identifier),
             Sequel.as(:digital_object__title, :title),
             Sequel.as(Sequel.lit('GetEnumValueUF(digital_object.digital_object_type_id)'), :objectType),
             Sequel.as(Sequel.lit('GetDigitalObjectDateExpression(digital_object.id)'), :dateExpression),
             Sequel.as(Sequel.lit('GetResourceIdentiferForInstance(instance_do_link_rlshp.instance_id)'), :resourceIdentifier)).
             filter(:repo_id => @repo_id)
  end
end
