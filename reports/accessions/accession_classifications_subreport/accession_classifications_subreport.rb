class AccessionClassificationsSubreport < AbstractReport

  def template
    "accession_classifications_subreport.erb"
  end

  def query
    db[:classification_rlshp]
      .left_outer_join(:classification, :classification__id => :classification_rlshp__classification_id)
      .left_outer_join(:classification_term, :classification_term__id => :classification_rlshp__classification_term_id)
      .filter(:accession_id => @params.fetch(:accessionId))
      .select(Sequel.as(:classification__identifier, :classificationIdentifier),
              Sequel.as(:classification__title, :classificationTitle),
              Sequel.as(:classification_term__identifier, :classificationTermIdentifier),
              Sequel.as(:classification_term__title, :classificationTermTitle))
  end

end
