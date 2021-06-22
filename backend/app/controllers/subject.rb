class ArchivesSpaceService < Sinatra::Base
  Endpoint.post("/subjects/:id")
    .description("Update a Subject")
    .params(["id", :id],
            ["subject", JSONModel(:subject), "The updated record", :body => true])
    .permissions([:update_subject_record])
    .example("shell") do
    <<~SHELL
        curl -H "X-ArchivesSpace-Session: $SESSION" \
        -d '{ "jsonmodel_type":"subject",
      "external_ids":[],
      "publish":true,
      "is_slug_auto":true,
      "used_within_repositories":[],
      "used_within_published_repositories":[],
      "terms":[{ "jsonmodel_type":"term",
      "term":"Term 1",
      "term_type":"topical",
      "vocabulary":"/vocabularies/2"}],
      "external_documents":[],
      "vocabulary":"/vocabularies/3",
      "authority_id":"http://www.example-18.com",
      "scope_note":"440FVOO",
      "source":"lcsh"}' \
        "http://localhost:8089/subjects/1"
    SHELL
  end
    .example("python") do
    <<~PYTHON
      from asnake.aspace import ASpace
      subj = aspace.subjects(1)
      # test to be sure that you got something
      if subj.__class__.__name__ == 'JSONModelObject':
        json_subj = subj.json()
        json_subj['source'] = 'lcsh'
        json_subj['authority_id'] = 'http://id.loc.gov/authorities/subjects/sh2016001442'  
        res = aspace.client.post(json_subj['uri'], json=json_subj)
        if res.status_code != 200:
          print(f'ERROR: {res.status_code}')
    PYTHON
  end
    .returns([200, :updated]) do
    with_record_conflict_reporting(Subject, params[:subject]) do
      handle_update(Subject, params[:id], params[:subject])
    end
  end

  Endpoint.post("/subjects")
    .description("Create a Subject")
    .params(["subject", JSONModel(:subject), "The record to create", :body => true])
    .permissions([:update_subject_record])
    .example("shell") do
    <<~SHELL
      curl -H "X-ArchivesSpace-Session: $SESSION" \
      -d '{ "jsonmodel_type":"subject",
      "external_ids":[],
      "publish":true,
      "is_slug_auto":true,
      "used_within_repositories":[],
      "used_within_published_repositories":[],
      "terms":[{ "jsonmodel_type":"term",
      "term":"Term 1",
      "term_type":"topical",
      "vocabulary":"/vocabularies/2"}],
      "external_documents":[],
      "vocabulary":"/vocabularies/3",
      "authority_id":"http://www.example-18.com",
      "scope_note":"440FVOO",
      "source":"lcsh"}' \
        "http://localhost:8089/subjects"
    SHELL
  end
    .example("python") do
    <<~PYTHON
      from asnake.aspace import ASpace
      from asnake.jsonmodel import JM
      # create a new subject
      # minimum requirements:
      # -  at least one Term object, with a term, a valid term_type, and  vocabulary (set to `/vocabularies/1')
      # - a defined source (e.g.: ingest, lcsh) and vocabulary (set to `/vocabularies/1')
      subj_json = JM.subject(source='ingest', vocabulary='/vocabularies/1' )
      term = JM.term(term='Black lives matter movement', term_type='topical',vocabulary='/vocabularies/1' )
      subj_json["terms"] = [term]
      res = aspace.client.post('/subjects', json=subj_json)
      subj_id = None
      if res.status_code ==  200:
        subj_id = res.json()["id"]
    PYTHON
  end
    .returns([200, :created]) do
    with_record_conflict_reporting(Subject, params[:subject]) do
      handle_create(Subject, params[:subject])
    end
  end

  Endpoint.get("/subjects")
    .description("Get a list of Subjects")
    .params()
    .paginated(true)
    .permissions([])
    .returns([200, "[(:subject)]"]) do
    handle_listing(Subject, params)
  end

  Endpoint.get("/subjects/:id")
    .description("Get a Subject by ID")
    .params(["id", :id])
    .permissions([])
    .example("shell") do
    <<~SHELL
      url -H "X-ArchivesSpace-Session: $SESSION" \
      "http://localhost:8089/subjects/1"
    SHELL
  end
    .example("python") do
    <<~PYTHON
      from asnake.aspace import ASpace
      subj = aspace.subjects(1)
      # test to be sure that you got something
      if subj.__class__.__name__ == 'JSONModelObject':
          json_subj = subj.json()
          print(f'Title: {json_subj["title"]}; Source: {json_subj["source"]}')
          if 'authority_id' in json_subj:
            print(f'Authority ID: {json_subj["authority_id"]}')
          else:
              print('Authority ID not defined')
    PYTHON
  end
    .returns([200, "(:subject)"]) do
    opts = { :calculate_linked_repositories => current_user.can?(:index_system) }
    json_response(Subject.to_jsonmodel(params[:id], opts))
  end

  Endpoint.delete("/subjects/:id")
    .description("Delete a Subject")
    .params(["id", :id])
    .permissions([:delete_subject_record])
    .example("shell") do
    <<~SHELL
      curl -H "X-ArchivesSpace-Session: $SESSION" \
      -X DELETE \
      "http://localhost:8089/subjects/1"  
    SHELL
  end
    .example("python") do
    <<~PYTHON
      from asnake.aspace import ASpace
      res = aspace.client.delete("http://localhost:8089/subjects/1")
    PYTHON
  end
    .returns([200, :deleted]) do
    handle_delete(Subject, params[:id])
  end
end
