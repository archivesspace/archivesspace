require_relative 'utils'

Sequel.migration do

  up do
    terms = ["abr", "acp", "act", "adi", "adp", "aft", "anl", "anm", "ann", "ant", "ape", "apl", "app", "aqt", "arc", "ard", "arr", "art", "asg", "asn", "ato", "att", "auc", "aud", "aui", "aus", "aut", "bdd", "bjd", "bkd", "bkp", "blw", "bnd", "bpd", "brd", "brl", "bsl", "cas", "ccp", "chr", "clb", "cli", "cll", "clr", "clt", "cmm", "cmp", "cmt", "cnd", "cng", "cns", "coe", "col", "com", "con", "cor", "cos", "cot", "cou", "cov", "cpc", "cpe", "cph", "cpl", "cpt", "cre", "crp", "crr", "crt", "csl", "csp", "cst", "ctb", "cte", "ctg", "ctr", "cts", "ctt", "cur", "cwt", "dbp", "dfd", "dfe", "dft", "dgg", "dgs", "dis", "dln", "dnc", "dnr", "dpc", "dpt", "drm", "drt", "dsr", "dst", "dtc", "dte", "dtm", "dto", "dub", "edc", "edm", "edt", "egr", "elg", "elt", "eng", "enj", "etr", "evp", "exp", "fac", "fds", "fld", "flm", "fmd", "fmk", "fmo", "fmp", "fnd", "fpy", "frg", "gis", "-grt", "his", "hnr", "hst", "ill", "ilu", "ins", "inv", "isb", "itr", "ive", "ivr", "jud", "jug", "lbr", "lbt", "ldr", "led", "lee", "lel", "len", "let", "lgd", "lie", "lil", "lit", "lsa", "lse", "lso", "ltg", "lyr", "mcp", "mdc", "med", "mfp", "mfr", "mod", "mon", "mrb", "mrk", "msd", "mte", "mtk", "mus", "nrt", "opn", "org", "orm", "osp", "oth", "own", "pan", "pat", "pbd", "pbl", "pdr", "pfr", "pht", "plt", "pma", "pmn", "pop", "ppm", "ppt", "pra", "prc", "prd", "pre", "prf", "prg", "prm", "prn", "pro", "prp", "prs", "prt", "prv", "pta", "pte", "ptf", "pth", "ptt", "pup", "rbr", "rcd", "rce", "rcp", "rdd", "red", "ren", "res", "rev", "rpc", "rps", "rpt", "rpy", "rse", "rsg", "rsp", "rsr", "rst", "rth", "rtm", "sad", "sce", "scl", "scr", "sds", "sec", "sgd", "sgn", "sht", "sll", "sng", "spk", "spn", "spy", "srv", "std", "stg", "stl", "stm", "stn", "str", "tcd", "tch", "ths", "tld", "tlp", "trc", "trl", "tyd", "tyg", "uvp", "vac", "vdg", "voc", "wac", "wal", "wam", "wat", "wdc", "wde", "win", "wit", "wpr", "wst"] 
    enum = self[:enumeration].filter(:name => 'linked_agent_archival_record_relators').select(:id).first 
    terms.each do |term|
      unless self[:enumeration_value].filter(:enumeration_id => enum[:id], :value => term).count > 0
        counter = self[:enumeration_value].filter(:enumeration_id => enum[:id]).order(:position).select(:position).last[:position]
        self[:enumeration_value].insert( :enumeration_id  => enum[:id], :value => term, :readonly => 0, :position => counter + 1 )
      end
    end
  
  end


  down do
  end

end

