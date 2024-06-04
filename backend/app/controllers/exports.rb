# frozen_string_literal: true

class ArchivesSpaceService < Sinatra::Base
  include ExportHelpers

  Endpoint.get('/repositories/:repo_id/digital_objects/dublin_core/:id.xml')
    .description("Get a Dublin Core representation of a Digital Object")
    .example("shell") do
      <<~SHELL
        curl -s -F password="admin" "http://localhost:8089/users/admin/login"
        set SESSION="session_id"
        curl -H "X-ArchivesSpace-Session: $SESSION" //
        "http://localhost:8089/repositories/2/digital_objects/dublin_core/48.xml" --output do_dublincore.xml
      SHELL
    end
    .example("python") do
      <<~PYTHON
        from asnake.client import ASnakeClient  # import the ArchivesSnake client

        client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
        # replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password

        client.authorize()  # authorizes the client

        do_dc = client.get("/repositories/2/digital_objects/dublin_core/48.xml")
        # replace 2 for your repository ID and 48 with your digital object ID. Find these at the URI on the staff interface

        with open("do_dc.xml", "wb") as file:  # save the file
            file.write(do_dc.content)  # write the file content to our file.
            file.close()
      PYTHON
    end
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "(:digital_object)"]) \
  do
    dc = generate_dc(params[:id])
    xml_response(dc)
  end

  Endpoint.get('/repositories/:repo_id/digital_objects/dublin_core/:id.:fmt/metadata')
    .description("Get metadata for a Dublin Core export")
    .example("shell") do
      <<~SHELL
        curl -s -F password="admin" "http://localhost:8089/users/admin/login"
        set SESSION="session_id"
        curl -H "X-ArchivesSpace-Session: $SESSION" //
        "http://localhost:8089/repositories/2/digital_objects/dublin_core/48.:fmt/metadata"
      SHELL
    end
    .example("python") do
      <<~PYTHON
        from asnake.client import ASnakeClient  # import the ArchivesSnake client

        client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
        # replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password

        client.authorize()  # authorizes the client

        do_dc = client.get("/repositories/2/digital_objects/dublin_core/48.fmt/metadata")
        # replace 2 for your repository ID and 48 with your digital object ID. Find these at the URI on the staff interface

        print(do_dc_fmt.content)
        # Sample output: {"filename":"identifier_youtube_20210218_182435_UTC__dc.xml","mimetype":"application/xml"}

        # For error handling, print or log the returned value of client.get with .json() - print(do_dc.json())
      PYTHON
    end
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "The export metadata"]) \
  do
    json_response({ 'filename' => safe_filename(DigitalObject[params[:id]].digital_object_id, '_dc.xml'),
                    'mimetype' => 'application/xml' })
  end

  Endpoint.get('/repositories/:repo_id/digital_objects/mets/:id.xml')
    .description("Get a METS representation of a Digital Object")
    .example("shell") do
      <<~SHELL
        curl -s -F password="admin" "http://localhost:8089/users/admin/login"
        set SESSION="session_id"
        curl -H "X-ArchivesSpace-Session: $SESSION" //
        "http://localhost:8089/repositories/2/digital_objects/mets/48.xml?dmd=PKG410P" --output do_mets.xml
      SHELL
    end
    .example("python") do
      <<~PYTHON
        from asnake.client import ASnakeClient  # import the ArchivesSnake client

        client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
        # replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password

        client.authorize()  # authorizes the client

        mets_xml = client.get("/repositories/2/digital_objects/mets/48.xml",
                              params={"dmd": "PKG410P"})
        # replace 2 for your repository ID and 48 with your digital object ID. Find these at the URI on the staff interface
        # replace PKG410P with your preferred DMD schema

        with open("do_mets.xml", "wb") as file:  # save the file
            file.write(mets_xml.content)  # write the file content to our file.
            file.close()
      PYTHON
    end
    .params(["id", :id],
            ["repo_id", :repo_id],
            ["dmd", String, "DMD Scheme to use", :optional => true])
    .permissions([:view_repository])
    .returns([200, "(:digital_object)"]) \
  do
    mets = generate_mets(params[:id], params[:dmd])
    xml_response(mets)
  end

  Endpoint.get('/repositories/:repo_id/digital_objects/mets/:id.:fmt/metadata')
    .description("Get metadata for a METS export")
    .example("shell") do
      <<~SHELL
        curl -s -F password="admin" "http://localhost:8089/users/admin/login"
        set SESSION="session_id"
        curl -H "X-ArchivesSpace-Session: $SESSION" \\
        "http://localhost:8089/repositories/2/digital_objects/mets/48.xml/metadata"
      SHELL
    end
    .example("python") do
      <<~PYTHON
        from asnake.client import ASnakeClient  # import the ArchivesSnake client

        client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
        # replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password

        client.authorize()  # authorizes the client

        mets_fmt = client.get("/repositories/2/digital_objects/mets/48.fmt/metadata")
        # replace 2 for your repository ID and 48 with your digital object ID. Find these at the URI on the staff interface

        print(mets_fmt.content)
        # Sample output: {"filename":"identifier_youtube_20210218_182435_UTC__mets.xml","mimetype":"application/xml"}

        # For error handling, print or log the returned value of client.get with .json() - print(mets_fmt.json())
      PYTHON
    end
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "The export metadata"]) \
  do
    json_response({ 'filename' =>
                    safe_filename(DigitalObject[params[:id]].digital_object_id, '_mets.xml'),
                    'mimetype' => 'application/xml' })
  end

  Endpoint.get('/repositories/:repo_id/digital_objects/mods/:id.xml')
    .description("Get a MODS representation of a Digital Object ")
    .example("shell") do
      <<~SHELL
        curl -s -F password="admin" "http://localhost:8089/users/admin/login"
        set SESSION="session_id"
        curl -H "X-ArchivesSpace-Session: $SESSION" \\
        "http://localhost:8089/repositories/2/digital_objects/mods/48.xml" --output do_mods.xml
      SHELL
    end
    .example("python") do
      <<~PYTHON
        from asnake.client import ASnakeClient  # import the ArchivesSnake client

        client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
        # replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password

        client.authorize()  # authorizes the client

        mods_xml = client.get("/repositories/2/digital_objects/mods/48.xml")
        # replace 2 for your repository ID and 48 with your digital object ID. Find these at the URI on the staff interface

        with open("do_mods.xml", "wb") as file:  # save the file
            file.write(mods_xml.content)  # write the file content to our file.
            file.close()
      PYTHON
    end
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "(:digital_object)"]) \
  do
    mods = generate_mods(params[:id])
    xml_response(mods)
  end

  Endpoint.get('/repositories/:repo_id/digital_objects/mods/:id.:fmt/metadata')
    .description("Get metadata for a MODS export")
    .example("shell") do
      <<~SHELL
        curl -s -F password="admin" "http://localhost:8089/users/admin/login"
        set SESSION="session_id"
        curl -H "X-ArchivesSpace-Session: $SESSION" //
        "http://localhost:8089/repositories/2/digital_objects/mods/48.fmt/metadata"
      SHELL
    end
    .example("python") do
      <<~PYTHON
        from asnake.client import ASnakeClient  # import the ArchivesSnake client

        client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
        # replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password

        client.authorize()  # authorizes the client

        mods_fmt = client.get("/repositories/2/digital_objects/mods/48.:fmt/metadata")
        # replace 2 for your repository ID and 48 with your digital object ID. Find these at the URI on the staff interface

        print(mods_fmt.content)
        # Sample output: {"filename":"identifier_youtube_20210218_182435_UTC__mods.xml","mimetype":"application/xml"}

        # For error handling, print or log the returned value of client.get with .json() - print(mods_fmt.json())
      PYTHON
    end
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "The export metadata"]) \
  do
    json_response({ 'filename' =>
                    safe_filename(DigitalObject[params[:id]].digital_object_id, '_mods.xml'),
                    'mimetype' => 'application/xml' })
  end

  Endpoint.get('/repositories/:repo_id/resources/marc21/:id.xml')
    .description("Get a MARC 21 representation of a Resource")
    .example("shell") do
      <<~SHELL
        curl -s -F password="admin" "http://localhost:8089/users/admin/login"
        set SESSION="session_id"
        curl -H "X-ArchivesSpace-Session: $SESSION" \\
        "http://localhost:8089/repositories/2/resources/marc21/577.xml?include_unpublished_marc=true;include_unpublished_notes=false" //
        --output marc21.xml
      SHELL
    end
    .example("python") do
      <<~PYTHON
        from asnake.client import ASnakeClient  # import the ArchivesSnake client

        client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
        # replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password

        client.authorize()  # authorizes the client

        marc21_xml = client.get("/repositories/2/resources/marc21/577.xml",
                                params={"include_unpublished_marc": True,
                                        "include_unpublished_notes": False})
        # replace 2 for your repository ID and 577 with your resource ID. Find these at the URI on the staff interface
        # set parameters to True or False

        with open("marc21.xml", "wb") as file:  # save the file
            file.write(marc21_xml.content)  # write the file content to our file.
            file.close()
      PYTHON
    end
    .params(["id", :id],
            ["repo_id", :repo_id],
            ["include_unpublished_marc", BooleanParam, "Include unpublished notes", :optional => true])
    .permissions([:view_repository])
    .returns([200, "(:resource)"]) \
  do

    marc = generate_marc(params[:id], params[:include_unpublished_marc])
    xml_response(marc)
  end

  Endpoint.get('/repositories/:repo_id/resources/marc21/:id.:fmt/metadata')
    .description("Get metadata for a MARC21 export")
    .example("shell") do
      <<~SHELL
        curl -s -F password="admin" "http://localhost:8089/users/admin/login"
        set SESSION="session_id"
        curl -H "X-ArchivesSpace-Session: $SESSION" \\
        "http://localhost:8089/repositories/2/resources/marc21/577.xml/metadata?include_unpublished_marc=true"
      SHELL
    end
    .example("python") do
      <<~PYTHON
        from asnake.client import ASnakeClient  # import the ArchivesSnake client

        client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
        # replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password

        client.authorize()  # authorizes the client

        marc21_fmt = client.get("/repositories/2/resources/marc21/577.:fmt/metadata",
                                params={"include_unpublished_marc": True})
        # replace 2 for your repository ID and 577 with your resource ID. Find these at the URI on the staff interface
        # set include_unpublished_marc to True or False

        print(marc21_fmt.content)
        # Sample output: {"filename":"identifier_20210218_182435_UTC__marc21.xml","mimetype":"application/xml"}

        # For error handling, print or log the returned value of client.get with .json() - print(marc21_fmt.json())
      PYTHON
    end
    .params(["id", :id],
            ["repo_id", :repo_id],
            ["include_unpublished_marc", BooleanParam, "Include unpublished notes", :optional => true])
    .permissions([:view_repository])
    .returns([200, "The export metadata"]) \
  do
    json_response({ 'filename' =>
                    safe_filename(Resource.id_to_identifier(params[:id]), '_marc21.xml'),
                    'mimetype' => 'application/xml' })
  end

  Endpoint.get('/repositories/:repo_id/resource_descriptions/:id.xml')
    .description("Get an EAD representation of a Resource")
    .example("shell") do
      <<~SHELL
        curl -s -F password="admin" "http://localhost:8089/users/admin/login"
        set SESSION="session_id"
        curl -H "X-ArchivesSpace-Session: $SESSION" \\
        "http://localhost:8089/repositories/2/resource_descriptions/577.xml?include_unpublished=false&include_daos=true&include_uris=true&numbered_cs=true&ead3=false" //
        --output ead.xml
      SHELL
    end
    .example("python") do
      <<~PYTHON
        from asnake.client import ASnakeClient  # import the ArchivesSnake client

        client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
        # replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password

        client.authorize()  # authorizes the client

        ead_xml = client.get("repositories/2/resource_descriptions/577.xml",
                             params={"include_unpublished": False,
                                     "include_daos": True,
                                     "numbered_cs": True,
                                     "ead3": False})
        # replace 2 for your repository ID and 577 with your resource ID. Find these at the URI on the staff interface
        # set parameters to True or False

        with open("ead.xml", "wb") as file:  # save the file
            file.write(ead_xml.content)  # write the file content to our file.
            file.close()

        # For error handling, print or log the returned value of client.get with .json() - print(ead_xml.json())
      PYTHON
    end
    .params(["id", :id],
            ["include_unpublished", BooleanParam,
             "Include unpublished records", :optional => true],
            ["include_daos", BooleanParam,
             "Include digital objects in dao tags", :optional => true],
            ["include_uris", BooleanParam,
             "Include unitid tags containing ArchivesSpace URIs", :optional => true],
            ["numbered_cs", BooleanParam,
             "Use numbered <c> tags in ead", :optional => true],
            ["repo_id", :repo_id],
            ["ead3", BooleanParam,
             "Export using EAD3 schema", :optional => true])
    .permissions([:view_repository])
    .returns([200, "(:resource)"]) \
  do
    ead_stream = generate_ead(params[:id],
                              (params[:include_unpublished] || false),
                              (params[:include_daos] || false),
                              (params[:include_uris]),
                              (params[:numbered_cs] || false),
                              (params[:ead3] || false))
    stream_response(ead_stream)
  end

  Endpoint.get('/repositories/:repo_id/resource_descriptions/:id.:fmt/metadata')
    .description("Get export metadata for a Resource Description")
    .example("shell") do
      <<~SHELL
        curl -s -F password="admin" "http://localhost:8089/users/admin/login"
        set SESSION="session_id"
        curl -H "X-ArchivesSpace-Session: $SESSION" \\
        "http://localhost:8089/repositories/2/resources/resource_descriptions/577.xml/metadata"
      SHELL
    end
    .example("python") do
      <<~PYTHON
        from asnake.client import ASnakeClient  # import the ArchivesSnake client

        client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
        # replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password

        client.authorize()  # authorizes the client

        res_fmt = client.get("/repositories/2/resource_descriptions/577.:fmt/metadata",
                             params={"fmt": "864442169P755"})
        # replace 2 for your repository ID and 577 with your resource ID. Find these at the URI on the staff interface
        # set fmt to the format of the request you would like to export

        print(res_fmt.content)
        # Sample output: {"filename":"identifier_20210218_182435_UTC__ead.fmt","mimetype":"application/:fmt"}

        # For error handling, print or log the returned value of client.get with .json() - print(res_fmt.json())
      PYTHON
    end
    .params(["id", :id],
            ["repo_id", :repo_id],
            ["fmt", String, "Format of the request",
                      :optional => true])
    .permissions([:view_repository])
    .returns([200, "The export metadata"]) \
  do
    json_response({ 'filename' => safe_filename(Resource.id_to_identifier(params[:id]), "_ead.#{params[:fmt]}"),
                    'mimetype' => "application/#{params[:fmt]}" })
  end

  Endpoint.get('/repositories/:repo_id/resource_labels/:id.tsv')
    .description("Get a tsv list of printable labels for a Resource")
    .example("shell") do
      <<~SHELL
        curl -s -F password="admin" "http://localhost:8089/users/admin/login"
        set SESSION="session_id"
        curl -H "X-ArchivesSpace-Session: $SESSION" \\
        "http://localhost:8089/repositories/2/resource_labels/577.tsv" --output container_labels.tsv
      SHELL
    end
    .example("python") do
      <<~PYTHON
        from asnake.client import ASnakeClient  # import the ArchivesSnake client

        client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
        # replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password

        client.authorize()  # authorizes the client

        request_labels = client.get("repositories/2/resource_labels/577.tsv")
        # replace 2 for your repository ID and 577 with your resource ID. Find these at the URI on the staff interface

        with open("container_labels.tsv", "wb") as local_file:
            local_file.write(request_labels.content)  # write the file content to our file.
            local_file.close()

        # For error handling, print or log the returned value of client.get with .json() - print(request_labels.json())
      PYTHON
    end
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "(:resource)"]) \
  do
    tsv = generate_labels(params[:id])

    tsv_response(tsv)
  end

  Endpoint.get('/repositories/:repo_id/resource_labels/:id.:fmt/metadata')
    .description("Get export metadata for Resource labels")
    .example("shell") do
      <<~SHELL
        curl -s -F password="admin" "http://localhost:8089/users/admin/login"
        set SESSION="session_id"
        curl -H "X-ArchivesSpace-Session: $SESSION" \\
        "http://localhost:8089/repositories/2/resource_labels/577.xml/metadata" --output labels.fmt
      SHELL
    end
    .example("python") do
      <<~PYTHON
        from asnake.client import ASnakeClient  # import the ArchivesSnake client

        client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
        # replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password

        client.authorize()  # authorizes the client

        labels_fmt = client.get("/repositories/2/resource_labels/577.:fmt/metadata")
        # replace 2 for your repository ID and 577 with your resource ID. Find these at the URI on the staff interface

        print(labels_fmt.content)
        # Sample output: {"filename":"identifier_20210218_182435_UTC__labels.tsv","mimetype":"text/tab-separated-values"}

        # For error handling, print or log the returned value of client.get with .json() - print(labels_fmt.json())
      PYTHON
    end
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "The export metadata"]) \
  do
    json_response({ 'filename' =>
                    safe_filename(Resource.id_to_identifier(params[:id]), '_labels.tsv'),
                    'mimetype' => 'text/tab-separated-values' })
  end

  Endpoint.get('/repositories/:repo_id/archival_contexts/people/:id.xml')
    .description("Get an EAC-CPF representation of an Agent")
    .example("shell") do
      <<~SHELL
        curl -s -F password="admin" "http://localhost:8089/users/admin/login"
        set SESSION="session_id"
        curl -H "X-ArchivesSpace-Session: $SESSION" \\
        "http://localhost:8089/repositories/2/archival_contexts/people/159.xml" --output eac_cpf.xml
      SHELL
    end
    .example("python") do
      <<~PYTHON
        from asnake.client import ASnakeClient  # import the ArchivesSnake client

        client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
        # replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password

        client.authorize()  # authorizes the client

        eac_cpf_xml = client.get("/repositories/2/archival_contexts/people/159.xml")
        # replace 2 for your repository ID and 159 with your agent ID. Find these at the URI on the staff interface

        with open("eac_cpf.xml", "wb") as file:  # save the file
            file.write(eac_cpf_xml.content)  # write the file content to our file.
            file.close()

        # For error handling, print or log the returned value of client.get with .json() - print(eac_cpf_xml.json())
      PYTHON
    end
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([])
    .returns([200, "(:agent)"]) \
  do
    eac = generate_eac(params[:id], 'agent_person')
    xml_response(eac)
  end

  Endpoint.get('/repositories/:repo_id/archival_contexts/people/:id.:fmt/metadata')
    .description("Get metadata for an EAC-CPF export of a person")
    .example("shell") do
      <<~SHELL
        curl -s -F password="admin" "http://localhost:8089/users/admin/login"
        set SESSION="session_id"
        curl -H "X-ArchivesSpace-Session: $SESSION" \\
        "http://localhost:8089/repositories/2/archival_contexts/people/159.xml/metadata"
      SHELL
    end
    .example("python") do
      <<~PYTHON
        from asnake.client import ASnakeClient  # import the ArchivesSnake client

        client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
        # replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password

        client.authorize()  # authorizes the client

        eac_cpf_fmt = client.get("/repositories/2/archival_contexts/people/159.:fmt/metadata")
        # replace 2 for your repository ID and 159 with your agent ID. Find these at the URI on the staff interface

        print(eac_cpf_fmt.content)
        # Sample output: {"filename":"title_20210218_182435_UTC__eac.xml","mimetype":"application/xml"}

        # For error handling, print or log the returned value of client.get with .json() - print(eac_cpf_fmt.json())
      PYTHON
    end
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([])
    .returns([200, "The export metadata"]) \
  do
    agent = AgentPerson.to_jsonmodel(params[:id])
    aname = agent['display_name']
    fn = [aname['authority_id'], aname['primary_name']].compact.join('_')
    json_response({ 'filename' => safe_filename(fn, '_eac.xml'),
                    'mimetype' => 'application/xml' })
  end

  Endpoint.get('/repositories/:repo_id/archival_contexts/corporate_entities/:id.xml')
    .description("Get an EAC-CPF representation of a Corporate Entity")
    .example("shell") do
      <<~SHELL
        curl -s -F password="admin" "http://localhost:8089/users/admin/login"
        set SESSION="session_id"
        curl -H "X-ArchivesSpace-Session: $SESSION" \\
        "http://localhost:8089/repositories/2/archival_contexts/corporate_entities/1238.xml" --output eac_cpf_corp.xml
      SHELL
    end
    .example("python") do
      <<~PYTHON
        from asnake.client import ASnakeClient  # import the ArchivesSnake client

        client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
        # replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password

        client.authorize()  # authorizes the client

        eac_cpf_corp_xml = client.get("/repositories/2/archival_contexts/corporate_entities/1238.xml")
        # replace 2 for your repository ID and 1238 with your corporate agent ID. Find these at the URI on the staff interface

        with open("eac_cpf_corp.xml", "wb") as file:  # save the file
            file.write(eac_cpf_corp_xml.content)  # write the file content to our file.
            file.close()

        # For error handling, print or log the returned value of client.get with .json() - print(eac_cpf_corp_xml.json())
      PYTHON
    end
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([])
    .returns([200, "(:agent)"]) \
  do
    eac = generate_eac(params[:id], 'agent_corporate_entity')
    xml_response(eac)
  end

  Endpoint.get('/repositories/:repo_id/archival_contexts/corporate_entities/:id.:fmt/metadata')
    .description("Get metadata for an EAC-CPF export of a corporate entity")
    .example("shell") do
      <<~SHELL
        curl -s -F password="admin" "http://localhost:8089/users/admin/login"
        set SESSION="session_id"
        curl -H "X-ArchivesSpace-Session: $SESSION" \\
        "http://localhost:8089/repositories/2/archival_contexts/corporate_entities/1238.xml/metadata"
      SHELL
    end
    .example("python") do
      <<~PYTHON
        from asnake.client import ASnakeClient  # import the ArchivesSnake client

        client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
        # replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password

        client.authorize()  # authorizes the client

        eac_cpf_corp_fmt = client.get("/repositories/2/archival_contexts/corporate_entities/1238.:fmt/metadata")
        # replace 2 for your repository ID and 1238 with your corporate agent ID. Find these at the URI on the staff interface

        print(eac_cpf_corp_fmt.content)
        # Sample output: {"filename":"title_20210218_182435_UTC__eac.xml","mimetype":"application/xml"}

        # For error handling, print or log the returned value of client.get with .json() - print(eac_cpf_corp_fmt.json())
      PYTHON
    end
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([])
    .returns([200, "The export metadata"]) \
  do
    agent = AgentCorporateEntity.to_jsonmodel(params[:id])
    aname = agent['display_name']
    fn = [aname['authority_id'], aname['primary_name']].compact.join('_')
    json_response({ 'filename' => safe_filename(fn, '_eac.xml'),
                    'mimetype' => 'application/xml' })
  end

  Endpoint.get('/repositories/:repo_id/archival_contexts/families/:id.xml')
    .description("Get an EAC-CPF representation of a Family")
    .example("shell") do
      <<~SHELL
        curl -s -F password="admin" "http://localhost:8089/users/admin/login"
        set SESSION="session_id"
        curl -H "X-ArchivesSpace-Session: $SESSION" \\
        "http://localhost:8089/repositories/2/archival_contexts/families/479.xml" --output eac_cpf_fam.xml
      SHELL
    end
    .example("python") do
      <<~PYTHON
        from asnake.client import ASnakeClient  # import the ArchivesSnake client

        client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
        # replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password

        client.authorize()  # authorizes the client

        eac_cpf_fam_xml = client.get("/repositories/2/archival_contexts/families/479.xml")
        # replace 2 for your repository ID and 479 with your family agent ID. Find these at the URI on the staff interface

        with open("eac_cpf_fam.xml", "wb") as file:  # save the file
            file.write(eac_cpf_fam_xml.content)  # write the file content to our file.
            file.close()

        # For error handling, print or log the returned value of client.get with .json() - print(eac_cpf_fam_xml.json())
      PYTHON
    end
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([])
    .returns([200, "(:agent)"]) \
  do
    eac = generate_eac(params[:id], 'agent_family')
    xml_response(eac)
  end

  Endpoint.get('/repositories/:repo_id/archival_contexts/families/:id.:fmt/metadata')
    .description("Get metadata for an EAC-CPF export of a family")
    .example("shell") do
      <<~SHELL
        curl -s -F password="admin" "http://localhost:8089/users/admin/login"
        set SESSION="session_id"
        curl -H "X-ArchivesSpace-Session: $SESSION" \\
        "http://localhost:8089/repositories/2/archival_contexts/families/479.:fmt/metadata" --output eac_cpf_fam.fmt
      SHELL
    end
    .example("python") do
      <<~PYTHON
        from asnake.client import ASnakeClient  # import the ArchivesSnake client

        client = ASnakeClient(baseurl="http://localhost:8089", username="admin", password="admin")
        # replace http://localhost:8089 with your ArchivesSpace API URL and admin for your username and password

        client.authorize()  # authorizes the client

        eac_cpf_fam_fmt = client.get("/repositories/2/archival_contexts/families/479.:fmt/metadata")
        # replace 2 for your repository ID and 479 with your family agent ID. Find these at the URI on the staff interface

        print(eac_cpf_fam_fmt.content)
        # Sample output: {"filename":"Adams_family_20210218_182435_UTC__eac.xml","mimetype":"application/xml"}

        # For error handling, print or log the returned value of client.get with .json() - print(eac_cpf_fam_fmt.json())
      PYTHON
    end
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([])
    .returns([200, "The export metadata"]) \
  do
    agent = AgentFamily.to_jsonmodel(params[:id])
    aname = agent['display_name']
    fn = [aname['authority_id'], aname['family_name']].compact.join('_')
    json_response({ 'filename' => safe_filename(fn, '_eac.xml'),
                    'mimetype' => 'application/xml' })
  end

  Endpoint.get('/repositories/:repo_id/agents/people/marc21/:id.xml')
          .description('Get an MARC Auth representation of an Person')
          .params(['id', :id],
                  ['repo_id', :repo_id])
          .permissions([:view_repository])
          .returns([200, '(:agent)']) \
  do
    ma = generate_marc_auth(params[:id], 'agent_person')
    xml_response(ma)
  end

  Endpoint.get('/repositories/:repo_id/agents/corporate_entities/marc21/:id.xml')
          .description('Get a MARC Auth representation of a Corporate Entity')
          .params(['id', :id],
                  ['repo_id', :repo_id])
          .permissions([:view_repository])
          .returns([200, '(:agent)']) \
  do
    ma = generate_marc_auth(params[:id], 'agent_corporate_entity')
    xml_response(ma)
  end

  Endpoint.get('/repositories/:repo_id/agents/families/marc21/:id.xml')
          .description('Get an MARC Auth representation of a Family')
          .params(['id', :id],
                  ['repo_id', :repo_id])
          .permissions([:view_repository])
          .returns([200, '(:agent)']) \
  do
    ma = generate_marc_auth(params[:id], 'agent_family')
    xml_response(ma)
  end

  Endpoint.get('/repositories/:repo_id/agents/people/marc21/:id.:fmt/metadata')
          .description('Get metadata for an MARC Auth export of a person')
          .params(['id', :id],
                  ['repo_id', :repo_id])
          .permissions([:view_repository])
          .returns([200, 'The export metadata']) \
  do
    agent = AgentPerson.to_jsonmodel(params[:id])
    aname = agent['display_name']
    fn = [aname['authority_id'], aname['primary_name']].compact.join('_')
    json_response({ 'filename' => safe_filename(fn, '_marc.xml'),
                    'mimetype' => 'application/xml' })
  end

  Endpoint.get('/repositories/:repo_id/agents/corporate_entities/marc21/:id.:fmt/metadata')
          .description('Get metadata for an MARC Auth export of a corporate entity')
          .params(['id', :id],
                  ['repo_id', :repo_id])
          .permissions([:view_repository])
          .returns([200, 'The export metadata']) \
  do
    agent = AgentCorporateEntity.to_jsonmodel(params[:id])
    aname = agent['display_name']
    fn = [aname['authority_id'], aname['primary_name']].compact.join('_')
    json_response({ 'filename' => safe_filename(fn, '_marc.xml'),
                    'mimetype' => 'application/xml' })
  end

  Endpoint.get('/repositories/:repo_id/agents/families/marc21/:id.:fmt/metadata')
          .description('Get metadata for an MARC Auth export of a family')
          .params(['id', :id],
                  ['repo_id', :repo_id])
          .permissions([:view_repository])
          .returns([200, 'The export metadata']) \
  do
    agent = AgentFamily.to_jsonmodel(params[:id])
    aname = agent['display_name']
    fn = [aname['authority_id'], aname['family_name']].compact.join('_')
    json_response({ 'filename' => safe_filename(fn, '_marc.xml'),
                    'mimetype' => 'application/xml' })
  end

  Endpoint.get('/repositories/:repo_id/resources/:id/templates/top_container_creation.csv')
    .description("Get a CSV template useful for bulk-creating containers for archival objects of a resource")
    .documentation do
      <<~DOCS
        This method returns a spreadsheet representing all the archival objects in a resource, with the following  fields:

        * Reference Fields (Non-editable):
          * Archival Object: ID, Ref ID, and Component ID
          * Resource: Title and Identifier
        * Editable Fields:
           * Top Container: Instance type, Type, Indicator, and Barcode
           * Child Container: Type, Indicator, and Barcode
           * Location: ID (the location must already exist in the system)

      DOCS
    end
    .example('shell') do
      <<~SHELL
        # Saves the csv to file 'resource_1_top_container_creation.csv'
        curl -H "X-ArchivesSpace-Session: $SESSION" \\
          "http://localhost:8089/repositories/2/resources/1/templates/top_container_creation.csv" \\
          > resource_1_top_container_creation.csv
      SHELL
    end
    .example('python') do
      <<~PYTHON
        from asnake.client import ASnakeClient

        client = ASnakeClient()
        client.authorize()

        with open('resource_1_top_container_creation.csv', 'wb') as file:
            resp = client.get('repositories/2/resources/1/templates/top_container_creation.csv')
            if resp.status_code == 200:
                file.write(resp.content)
    PYTHON
    end
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "The CSV template"]) \
  do
    attachment "resource_#{params[:id]}_top_containers.csv"
    CsvTemplateGenerator.csv_for_top_container_generation(params[:id])
  end

  Endpoint.get('/repositories/:repo_id/resources/:id/templates/digital_object_creation.csv')
    .description("Get a CSV template useful for bulk-creating digitial objects for archival objects of a resource")
    .documentation do
      <<~DOCS
        This method returns a spreadsheet representing all the archival objects in a resource, with the following  fields:

        * Reference Fields (Non-editable):
          * Resource URI: Resource URI
          * Archival Object URI: Archival Object URI
      DOCS
    end
    .example('shell') do
      <<~SHELL
        # Saves the csv to file 'resource_1_digital_object_creation.csv'
        curl -H "X-ArchivesSpace-Session: $SESSION" \\
          "http://localhost:8089/repositories/2/resources/1/templates/digital_object_creation.csv" \\
          > resource_1_digital_object_creation.csv
      SHELL
    end
    .example('python') do
      <<~PYTHON
        from asnake.client import ASnakeClient

        client = ASnakeClient()
        client.authorize()

        with open('resource_1_digital_object_creation.csv', 'wb') as file:
            resp = client.get('repositories/2/resources/1/templates/digital_object_creation.csv')
            if resp.status_code == 200:
                file.write(resp.content)
    PYTHON
    end
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "The CSV template"]) \
  do
    attachment "resource_#{params[:id]}digital_objects.csv"
    CsvTemplateGenerator.csv_for_digital_object_generation(params[:id])
  end
end
