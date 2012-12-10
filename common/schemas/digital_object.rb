{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "type" => "object",
    "uri" => "/repositories/:repo_id/digital_objects",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},

      "digital_object_id" => {"type" => "string", "ifmissing" => "error"},
      "publish" => {"type" => "boolean", "default" => true},
      "level" => {"type" => "string", "enum" => ["collection", "work", "image"]},
      "title" => {"type" => "string"},
      "digital_object_type" => {
        "type" => "string",
        "enum" => [
                   "cartographic",
                   "mixed_materials",
                   "moving_image",
                   "notated_music",
                   "software_multimedia",
                   "sound_recording",
                   "sound_recording_musical",
                   "sound_recording_nonmusical",
                   "still_image",
                   "text"
                  ]
      },

      "language" => {"type" => "string", "enum" => ["aar","abk","ace","ach","ada","ady","afa","afh","afr","ain","aka","akk","alb","ale","alg","alt","amh","ang","anp","apa","ara","arc","arg","arm","arn","arp","art","arw","asm","ast","ath","aus","ava","ave","awa","aym","aze","bad","bai","bak","bal","bam","ban","baq","bas","bat","bej","bel","bem","ben","ber","bho","bih","bik","bin","bis","bla","bnt","bos","bra","bre","btk","bua","bug","bul","bur","byn","cad","cai","car","cat","cau","ceb","cel","cha","chb","che","chg","chi","chk","chm","chn","cho","chp","chr","chu","chv","chy","cmc","cop","cor","cos","cpe","cpf","cpp","cre","crh","crp","csb","cus","cze","dak","dan","dar","day","del","den","dgr","din","div","doi","dra","dsb","dua","dum","dut","dyu","dzo","efi","egy","eka","elx","eng","enm","epo","est","ewe","ewo","fan","fao","fat","fij","fil","fin","fiu","fon","fre","frm","fro","frr","frs","fry","ful","fur","gaa","gay","gba","gem","geo","ger","gez","gil","gla","gle","glg","glv","gmh","goh","gon","gor","got","grb","grc","gre","grn","gsw","guj","gwi","hai","hat","hau","haw","heb","her","hil","him","hin","hit","hmn","hmo","hrv","hsb","hun","hup","iba","ibo","ice","ido","iii","ijo","iku","ile","ilo","ina","inc","ind","ine","inh","ipk","ira","iro","ita","jav","jbo","jpn","jpr","jrb","kaa","kab","kac","kal","kam","kan","kar","kas","kau","kaw","kaz","kbd","kha","khi","khm","kho","kik","kin","kir","kmb","kok","kom","kon","kor","kos","kpe","krc","krl","kro","kru","kua","kum","kur","kut","lad","lah","lam","lao","lat","lav","lez","lim","lin","lit","lol","loz","ltz","lua","lub","lug","lui","lun","luo","lus","mac","mad","mag","mah","mai","mak","mal","man","mao","map","mar","mas","may","mdf","mdr","men","mga","mic","min","mis","mkh","mlg","mlt","mnc","mni","mno","moh","mon","mos","mul","mun","mus","mwl","mwr","myn","myv","nah","nai","nap","nau","nav","nbl","nde","ndo","nds","nep","new","nia","nic","niu","nno","nob","nog","non","nor","nqo","nso","nub","nwc","nya","nym","nyn","nyo","nzi","oci","oji","ori","orm","osa","oss","ota","oto","paa","pag","pal","pam","pan","pap","pau","peo","per","phi","phn","pli","pol","pon","por","pra","pro","pus","qaa-qtz","que","raj","rap","rar","roa","roh","rom","rum","run","rup","rus","sad","sag","sah","sai","sal","sam","san","sas","sat","scn","sco","sel","sem","sga","sgn","shn","sid","sin","sio","sit","sla","slo","slv","sma","sme","smi","smj","smn","smo","sms","sna","snd","snk","sog","som","son","sot","spa","srd","srn","srp","srr","ssa","ssw","suk","sun","sus","sux","swa","swe","syc","syr","tah","tai","tam","tat","tel","tem","ter","tet","tgk","tgl","tha","tib","tig","tir","tiv","tkl","tlh","tli","tmh","tog","ton","tpi","tsi","tsn","tso","tuk","tum","tup","tur","tut","tvl","twi","tyv","udm","uga","uig","ukr","umb","und","urd","uzb","vai","ven","vie","vol","vot","wak","wal","war","was","wel","wen","wln","wol","xal","xho","yao","yap","yid","yor","ypk","zap","zbl","zen","zha","znd","zul","zun","zxx","zza",]},

      "restrictions" => {"type" => "boolean", "default" => false},

      "subjects" => {"type" => "array", "items" => {"type" => "JSONModel(:subject) uri_or_object"}},
      "extents" => {"type" => "array", "items" => {"type" => "JSONModel(:extent) object"}},
      "dates" => {"type" => "array", "items" => {"type" => "JSONModel(:date) object"}},
      "external_documents" => {"type" => "array", "items" => {"type" => "JSONModel(:external_document) object"}},

      "notes" => {
        "type" => "array",
        "items" => {"type" => [{"type" => "JSONModel(:note_bibliography) object"},
                               {"type" => "JSONModel(:note_digital_object) object"}]},
      },

      "linked_agents" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "properties" => {
            "role" => {
              "type" => "string",
              "enum" => ["creator", "source", "subject"],
              "ifmissing" => "error",
            },

            "ref" => {"type" => [{"type" => "JSONModel(:agent_corporate_entity) uri"},
                                 {"type" => "JSONModel(:agent_family) uri"},
                                 {"type" => "JSONModel(:agent_person) uri"},
                                 {"type" => "JSONModel(:agent_software) uri"}],
                      "ifmissing" => "error"}
          }
        }
      },

    },

    "additionalProperties" => false
  },
}
