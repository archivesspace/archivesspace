# ANW-2229: Refactoring search logic, fix current issues, improve maintainability

## Context

Jira: <https://archivesspace.atlassian.net/browse/ANW-2229>. Status: Ready for Implementation. Implements roadmap idea **ASRM-27**.

**Guiding principle: no catchall fields.** A *catchall* is a synthetic Solr field that aggregates content from many distinct sources into one searchable bag: the `fullrecord` / `fullrecord_published` tree-walk dump (`indexer_common.rb:140-207`), the `notes` / `notes_published` pair (the walker's narrower sibling, merged via `<copyField>` in `solr/schema.xml:36`), and any future field of the same shape. Catchalls are convenient (one field for edismax `qf` to weight) but structurally hostile to every issue this refactoring needs to fix - see "Linked-ticket clusters (motivation)".

The refactor adopts the inverse position: **every searchable field is a real source solr field with an explicit name; relevance configuration enumerates those names directly** via named `<initParams>` paramsets in `solrconfig.xml` (P2.1); **fields not enumerated in any paramset are not searchable by default**. This goes one step further than Arclight, which keeps a `text` catchall fed by `<copyField>` (see "Reference: how Arclight does it", point 3). The allow-list becomes finite and reviewable; defects become attributable to a single source field; per-field decisions (analyzer, highlighting, publish-scope, facet routing) become possible. The `creators` / `published_creators` split in P2.8 follows the same principle on the facet/filter side: one field per (scope, publish-state) combination, no audience-mixing field doing double duty.

Scope boundary:

- The `json` display blob is **retained** with `indexed="false"`. This project does **not** refactor the presentation layer that deserializes it (`public/app/models/record.rb` and its consumers). It changes only the relevance query and the search-index fields that feed it. New searchable fields are added **alongside** the blob, not as a replacement for it.

- It is OK to touch presentation code where a search feature requires it (for example, rendering highlighted snippets in the result list). What is out of scope is dropping the blob and rewriting the record-display read path.

Notes:

- It is expected that a complete solr reindex would be necessary after upgrading to the ArchivesSpace version that will include this refactoring.

### Linked-ticket clusters (motivation)

The linked tickets cluster into themes the current architecture makes hard to fix correctly:

- **Unexplainable matches**: ANW-2657 (subject/term URIs in PUI hits), ANW-201 (top-container info leaks), ANW-1672 (agent contacts/events appear). All caused by `IndexerCommon.extract_string_values` (`indexer/app/lib/indexer_common.rb:140-207`) walking the entire record JSON and concatenating every string into `fullrecord_published` / `fullrecord`. The walker is type-blind, so URIs (`/subjects/45`), internal IDs, staff-only metadata, top-container barcodes, and agent contacts all flow into the search index alongside genuine content. The symptom: a researcher types `45`, gets resource X, opens it, and sees no `45` anywhere in title / notes / dates / agents - the real match was a subject URI like `/subjects/45`, a top-container barcode, or an internal event ID.
  - **Fixed in P2.2-P2.4** by removing the walker entirely (along with the `fullrecord` and `fullrecord_published` synthetic fields it produced) and routing default keyword search to a `qf_default` paramset in `solrconfig.xml` whose `qf` enumerates the source fields explicitly. Fields not listed in any paramset's `qf` are not searchable by default; URIs / internal IDs / staff-only fields are excluded by omission (a finite, reviewable allow-list instead of an unbounded deny-list).

- **Identifier search**: ANW-290, ANW-1556, ANW-2071, ANW-2075. IDs reach the index only through the `fullrecord` catchall and a coarse single-valued `identifier` field; partial / multi-part / "contains" semantics are broken. Multi-part identifiers like `MS-2024-001` don't match `MS2024001` or `MS 2024 001`; advanced search "Identifier contains" misses obvious substring matches; users typing a known catalogue number don't always find the record.
  - **Fixed in P2.5** by adopting Arclight's `identifier_match` field type (WordDelimiterGraphFilter with `catenateAll=1`, which generates concatenated token variants at index time so any catenation matches any other), and by defining a `qf_identifier` paramset in `solrconfig.xml` that enumerates every identifier-bearing field (`id`, `ead_id`, `ref_id`, `component_id`, `digital_object_id`, `identifier_match`, `unitid_ssm`) with appropriate boosts; the identifier-context paramset is invoked via `useParams=qf_identifier`.

- **Analyzer chain**: ANW-308 (brackets), ANW-1686 (ampersands), ANW-859 (partial matches), ANW-1178 (non-Roman scripts). Driven by the `text_general` analyzer in `solr/schema.xml` and the lack of per-field tokenization choices. The stock analyzer silently drops bracket characters (so `[2024]` becomes searchable as `2024` with no way to query the literal brackets), breaks facet-filter URLs on ampersands, defaults to `mm=1` (minimum should match = any-term) so multi-term queries return weak partial matches, and has no Unicode folding for Cyrillic / Arabic / Hebrew / Greek / CJK scripts.
  - **Fixed in P2.6** by switching the field type backing `*_tesim` dynamic fields to `ICUTokenizerFactory` + `ICUFoldingFilterFactory` (covers all Unicode scripts), adding a `string_punct_stop` field type to treat `& : ; [ ]` as query-side stopwords where appropriate, and setting `mm=4<90%` (1-4 terms: all required; 5+ terms: 90%) on every paramset so short queries require all terms and long queries require 90%; the seven MLC per-language analyzer chains (PR #4046) apply to per-language `*_<iso>_<script>_tesim` fields independently.

- **Highlighting / display**: ANW-2315 (note hits not highlighted in summary). `summary` is derived from `notes` by picking one specific note at index time - first abstract, else first scopecontent. Everything else (bioghist, accessrestrict, processinfo, custodhist, …) is ignored. The chosen note is stored in doc['summary'] which is indexed="false" - the highlighter cannot run against it.
  - **Fixed in P2.7**
    - (a) The existing `summary` field is made highlightable: `IndexerCommon.add_summary` and its note-selection logic (first abstract, else first scopecontent) are unchanged, the displayed summary is unchanged, and the only schema change is flipping `summary` from `indexed="false"` to `indexed="true"` with a text analyzer aligned to the searchable fields so Solr's highlighter can run against it. `summary` is added to `hl.fl` but to no `qf` paramset - display-and-highlight only, never a search target.
    - (b) The separate result-list found in block is driven by the **published** per-note-type `*_tesim` fields P2.2 emits, so it attributes a match to the exact note it came from ("Found in: Biographical/Historical Note: …"). Only the published `<type>_tesim` fields go into the PUI `hl.fl`; the `<type>_unpublished_tesim` companions never do, so unpublished note text cannot leak into a highlight.
    - This means: a term highlights in the `summary` itself only when it occurs in the abstract/scopecontent the summary was built from; matches in any other published note appear in the per-note highlights block instead.

- **Filter correctness**:
  - ANW-262 (PUI Creator filter includes unpublished creators),
    - The `creator` field mixes published and unpublished agents so filtering by Creator returns records whose only matching creator is unpublished (a privacy-relevant defect, since a researcher should never see references to suppressed agents).
    - **Fixed in P2.8** by adding `published_creators` as a separate stored field (only published linked agents in creator role)
  - ANW-1580 (level facet inaccurate),
    - The `level` field is written by three separate code paths (`indexer_common.rb:306, 529, 549`) with inconsistent `otherlevel → other_level` substitution, so facet counts diverge from the level displayed on each record.
    - **Fixed in P2.8** by collapsing the three level writers into one with consistent substitution across resource / archival_object / digital_object;
  - the backend routes Creator and Level facet filters to the new fields.
  - ANW-1102 / ANW-862 / ANW-1628 are reassessed against the new schema after P2.8 lands; they may close trivially or need a small follow-up.

- **Typeahead relevancy**: ANW-2656. Linker typeaheads (Agent picker, Subject picker, Resource picker) don't prioritise the right fields: searching for "Smith" in the Agent linker returns records where "Smith" appears in notes, biographies, or addresses *before* records where "Smith" is the actual agent name, because the global `qf` weights titles and identifiers but not name fields specifically.
  - **Fixed in P2.1** by defining per-search-type `qf` paramsets in `solrconfig.xml` (`qf_name`, `qf_subject`, `qf_title`, etc.) and propagating the linker type through to the backend (`linker.html.erb` + `linker.js`) so the right paramset applies: the Agent linker uses `qf_name` (prioritises name fields over notes), the Subject linker uses `qf_subject`, the Resource linker uses `qf_title` plus identifier weighting.

- **Indexer reliability**: ANW-902 (PUI indexer occasionally drops AOs from new EADs). Symptom: components from a freshly imported EAD don't appear in PUI search until the next periodic reindex, suggesting a race condition or transaction-boundary bug in the incremental-update path. Not driven by schema shape, so handled separately as out-of-scope item X.2 rather than within an ANW-2229 phase.

### Structural framing

- The schema **already has dedicated indexed fields** for most things (`title`, `identifier`, `notes`, `notes_published`, `agents`, `creators`, `subjects`, `dates`, `extents`, `langcode`, `level`: `solr/schema.xml:4-150`).
- The `json` blob (`schema.xml:44`) is **redundant for searching** but **essential for display**: it exists to let one Solr request carry enough data to render result lists and show pages, via **deserialization in the public UI** (`public/app/models/record.rb:19-25`). It is retained.
- `fullrecord` and `fullrecord_published` are built by a **type-blind tree walk** (`indexer_common.rb:140-207`) that grabs every string in the record, including URIs and internal IDs. These are search catchalls and are removed by this project.

### Field naming: suffix new search fields, leave existing fields unchanged

New search fields this project adds follow the Blacklight dynamic-field suffix convention (`*_tesim`, `*_ssim`; see "Reference: how Arclight does it", point 2). Existing Solr fields (`title`, `notes`, `creators`, `subjects`, `identifier`, `level`, `langcode`, `primary_type`, etc.) **keep their current plain names and are not renamed**. The post-refactor schema is therefore deliberately mixed-style: legacy plain-named fields alongside new suffixed fields.

Renaming the existing fields to the convention was considered and rejected. For *existing* fields the cost is high and the benefit is small:

- **It would break the public query API.** The `/search` endpoint accepts raw Solr field names from callers: Lucene `q` (`title:foo`), `sort`, `facet[]`, `filter_query`. The PUI embeds facet field names directly in query-string parameters, so every bookmarked or shared faceted-search URL contains Solr field names. Renaming `title` to `title_tesim` (and so on) breaks external API integrations, shared / bookmarked search URLs, and any saved searches.
- **It would silently break plugins.** Core field names are an implicit contract for plugins that write fields via `add_document_prepare_hook` or run their own Solr queries. A rename produces no compile-time error: the plugin keeps writing the old name, the core queries the new one, and results silently go empty.
- **It would not capture the convention's main benefit.** The primary payoff of the suffix convention is that `*_tesim` and friends are Solr `<dynamicField>` patterns, so emitting a new field needs no schema declaration. Existing fields are already declared; renaming them removes no future schema edits. Only the secondary benefit (self-documenting names) would apply, in exchange for all of the cost above.

The accepted cost of this decision is the cosmetic inconsistency of a mixed-style schema. The P1.3 Solr field map records every field under its actual name, so the mixed state is documented rather than hidden. If a fully uniform schema is ever wanted, it belongs in its own breaking-change, major-version effort with a field-alias / deprecation plan, not in this epic.

### The serialize / deserialize pattern (retained)

The indexer serializes each record to a JSON string at `indexer_common.rb:1280` (`doc['json'] = ASUtils.to_json(sanitize_json(values))`). On every search hit the public UI deserializes that string at `public/app/models/record.rb:19-25` (`@json = ASUtils.json_parse(solr_result['json'])`); ~480 lines of `record.rb` and per-type subclasses then read `@json[...]` directly.

The blob is `indexed="false"`. Its sole purpose is letting **one** Solr request carry enough data to render result lists and show pages without N backend lookups. **Solr is the PUI's read database**: `public/app/services/archives_space_client.rb` reads record content exclusively through two Solr-backed endpoints (`/search` and `/search/records`). The only direct PUI→backend traffic that bypasses Solr is slug resolution and login.

This pattern is **left in place**. An earlier draft of this plan proposed replacing the blob with explicit per-field stored display fields and rewriting `record.rb`; that work is now out of scope. This project adds searchable fields and relevance configuration; the blob continues to carry display data unchanged.

### Tree display (Collection Overview / Collection Organization) is unaffected

The PUI renders two tree-related views for a resource - the **Collection Overview** (the resource show page) and the **Collection Organization** (the hierarchical finding-aid tree). Both must keep working after every Phase 2 change. They do, because none of the tree-rendering path is in scope:

- **Tree docs never use the walker.** `large_tree_doc_indexer.rb` builds the `tree_root` / `tree_waypoint` / `tree_node` / `tree_node_from_root` docs; each carries only `id`, `uri`, `pui_parent_id`, `publish`, `primary_type`, `types`, and a `json` payload. It never calls `extract_string_values` or `build_fullrecord`, so P2.4's walker removal is a no-op for tree docs. None of the fields tree docs use is dropped or re-analyzed by any P2.x ticket.
- **The tree fetch is a URI lookup, not a relevance query, and is out of scope.** The PUI fetches tree docs via `get_raw_record(uri + '/tree/root')` and the `resources_controller.rb` `tree_root` / `tree_waypoint` / `tree_node` actions, which call `/search/records` - a lookup by record URI carrying no edismax `qf`. P2.1's paramset / `useParams` work (keyword / identifier / linker requests only) does not touch it. The tree views read the retained `json` blob and are in the "JSON-blob consumers (retained as-is)" list.
- **Collection Overview is the resource show page**, fed by `/search/records` reading the retained `json` blob via `record.rb` - also retained.

P1.1 adds characterization specs for the tree-doc indexer (real assertions on `tree_root` / `tree_waypoint` / `tree_node`); each Phase 2 PR is additionally verified against a reindexed multi-level resource (see "Verification (Phase 2)").

The obsolete pre-large-tree code path (the `/search/published_tree` endpoint, `ArchivesSpaceClient#get_tree`, the `Tree` model, and the unused `tree_json` / `whole_tree_json` / `node_uri` Solr fields) was dead and has been removed separately under ANW-2757 (PR #4094); it is unrelated to this refactor.

## Reference: how Arclight does it

Arclight (`projectblacklight/arclight`) is the closest active reference: Blacklight-based discovery for EAD-described archival material. This project borrows Arclight's **search-side** patterns; it does **not** adopt Arclight's display-field architecture.

1. **Individual stored display fields (not adopted).** Arclight has no JSON blob: display fields are individual stored fields (`abstract_html_tesm`, `extent_ssm`, `creator_ssim`). ArchivesSpace retains its `json` blob as the PUI's display payload; the public UI is a Solr-read application and this project does not refactor that read path. We borrow the search-side patterns below, not the display-field model.
2. **Blacklight dynamic-field suffix convention.** Each suffix encodes (type, stored, indexed, multivalued), so a new field needs no per-field `<field>` declaration in the Solr schema: a single `<dynamicField>` pattern (`*_tesim` and the like) covers every field carrying that suffix. Decoded left-to-right after the underscore:

   | Position    | Letters                             | Meaning                                                                        |
   | ----------- | ----------------------------------- | ------------------------------------------------------------------------------ |
   | Type        | `t` / `te` / `s` / `i` / `dt` / `b` | text / text-English-analyzed / string (untokenized) / integer / date / boolean |
   | Stored      | `s`                                 | returned in search results                                                     |
   | Indexed     | `i`                                 | searchable / facetable / sortable                                              |
   | Multivalued | `m`                                 | array, not scalar                                                              |

   The new search fields this project adds use two suffixes:

   - **`_tesim`**: text-English, stored, indexed, multivalued. Full-text-searchable content (per-note-type bodies, etc.). "Stored" here is for the highlighter, which needs a stored copy to compute snippets; it is not a display-read path.
   - **`_ssim`**: string, stored, indexed, multivalued. Untokenized exact-match: facetable values (e.g. `published_creators`).

   Arclight also uses display-only suffixes (`_ssm` string stored-not-indexed, `_html_tesm` HTML payload stored-not-indexed). This project does **not** need them: note and field display continue to read the retained `json` blob. Other suffixes you'll see in Arclight: `_si` (string indexed scalar), `_isi` (integer stored indexed scalar), `_isim` (integer stored indexed multivalued), `_dtsim` (date stored indexed multivalued).
3. **No catchall, no tree walker; default search routes to a paramset enumerating its source fields directly.** Arclight does have a `text` catchall populated via `<copyField>` (Arclight `schema.xml:376-402`), but our plan goes one step further: instead of catchall + paramsets, we use paramsets only. The `qf_default` paramset's `qf` enumerates the source fields. Adding a field to default search means editing one paramset; URIs / internal IDs / staff fields are excluded by being absent from every paramset's `qf`. Direct fix for ANW-2657, ANW-201, ANW-1672 with the same allow-list semantics, no synthetic field, no copyField.
4. **Specialized identifier field types via paramset.** `identifier_match` (Arclight `schema.xml:175-195`) uses `WordDelimiterGraphFilterFactory` with `catenateAll=1` so multi-part IDs match in any catenation. We adopt the field type and route identifier-context searches via a `qf_identifier` paramset that enumerates `id`, `ead_id`, `ref_id`, `component_id`, `digital_object_id`, `identifier_match`, `unitid_ssm` directly (no `identifier_search` copyField catchall, same logic as point 3). Direct fix for the Identifier-search cluster.
5. **Per-field analyzer choices.** Arclight assigns analyzers per field instead of one `text_general` everywhere - the stock Solr `text_en` (stemming + synonyms), an ICU-based field type for `*_tesim` (ICU tokenizer + ICU folding), `string_punct_stop` (treats `& : ;` as query-side stopwords). P2.6 adopts the per-field principle, using `text_icu` for `*_tesim` (ArchivesSpace is multilingual, so not the English-only `text_en`). Direct fix for the Analyzer-chain cluster.
6. **Block-join nested docs for the collection/component hierarchy** (`_root_`, `_nest_parent_`, `_nest_path_`). Would let us drop `RecordInheritance.merge` and the `large_tree_doc_indexer` waypoint hack. Out of scope for this project (item X.1).
7. **Field-specific search handlers via named paramsets.** `qf_identifier` / `pf_identifier` / `qf_name` / `qf_place` / `qf_subject` / `qf_title` / `qf_container` declared as `<initParams>` blocks in `solrconfig.xml`, invoked from the controller via the `useParams=<name>[,<name>...]` request parameter (composable for layered configurations like locale boosts on top of a default). ArchivesSpace currently builds a single `qf` string in Ruby and tacks it onto every request (`backend/app/model/solr.rb:345-350`); the proposed shape moves all relevance configuration into `solrconfig.xml` and the per-request work shrinks to picking paramset names. Cheaper to tune (no Ruby redeploy), easier to audit (one file), composable.
8. **`mm=4<90%`**: minimum-should-match. ArchivesSpace's edismax has no `mm` set today. Affects ANW-859.
9. **Suggester + spellcheck wired to a curated list of source fields directly** (no catchall to draw from). Optional follow-up; the source-field list mirrors the `qf_default` paramset's enumeration.

**What does not carry over:** Arclight indexes from EAD XML via Traject (ArchivesSpace indexes resolved JSON via `IndexerCommon`); Arclight is read-only on Solr (ArchivesSpace's frontend writes via the backend); Arclight has no plugin hook surface, and ours must be preserved; Arclight has no JSON display blob, and ours is retained.

**Net effect:** this project adopts Arclight's search-side patterns (no catchall, per-field enumeration, `identifier_match`, ICU analyzers, named paramsets, `mm`) and the `*_tesim` / `*_ssim` suffix convention for the new search fields. It does not adopt Arclight's no-blob display architecture.

## MLC coordination (ANW-2282 / MCTF)

The Multilingual Content (MLC) project (epic ANW-2282 / Jira project MCTF) overlaps this refactor in indexing and search. Two MLC PRs are relevant: PR #3994 lays the `_mlc` MySQL tables and the `MultilingualContent` mixin; [PR #4046](https://github.com/archivesspace/archivesspace/pull/4046) adds the indexing plumbing. Neither is merged to master yet. The MLC plan is at `mctf_implementation_plan.md` (on the `ANW-2282-mlc-backwards-compatible` branch); the bits that touch this refactor are in §5.

Both projects land coordinated changes to `solr/schema.xml`, `indexer/app/lib/indexer_common.rb`, and `backend/app/model/solr.rb`. The two are unified on a single Solr field-naming convention for **searchable** multilingual fields and a single relevance-paramset model. The unified design is documented in **MCTF plan §5.5**; the summary below captures only what affects ANW-2229 sub-tickets.

### Unified design summary

1. **One field-naming convention for searchable multilingual fields.** Every multilingual field that should be searchable becomes `<field>_<iso>_<script>_tesim` (indexed and stored; stored for the highlighter), with a `<field>_primary_tesim` companion populated from the record's primary language. Non-multilingual search fields use plain Blacklight suffixes (`identifier_ssim`, etc.). The 7 curated `<fieldType>` definitions (`text_eng`, `text_spa`, `text_fre`, `text_jpn`, `text_ger`, `text_ukr`, `text_dut`) and the `solr/lang/` stopword / contraction / stemdict files from MLC PR #4046 are kept unchanged.
2. **No catchall; default search via paramset enumeration.** `IndexerCommon.extract_string_values` and the synthetic `fullrecord` / `fullrecord_published` fields are removed (this refactor's P2.4). Default keyword search routes to a `qf_default` paramset whose `qf` enumerates the source fields directly, including per-language variants per record type. Per-locale paramsets (`qf_locale_<iso>_<script>`) layer locale-aware boosts on top via `useParams=qf_default,qf_locale_<active>`. MLC's reliance on the walker to funnel `mlc_fields` into `fullrecord` (MCTF §5.3) goes away with the walker; per-language search fields enter the index directly via the indexer's `document_prepare_hook`.
3. **JSON blob retained.** The `json` display blob stays. The `mlc_fields` JSON key (built by `MultilingualContent::ClassMethods.attach_mlc_fields_to_jsons!`) remains in the record JSON and in the blob, used for display exactly as today. Per-language *searchable* content is additionally emitted into named `*_<iso>_<script>_tesim` Solr fields for the relevance query. Search and display are two separate representations; this project owns the search one only.
4. **Tree docs.** PR #4046 introduced per-language tree-doc fan-out. Whether to collapse that into one tree-doc set per tree carrying every-language fields is an MLC decision (MCTF §5.5.3); it is not an ANW-2229 deliverable. ANW-2229's only interaction is that the walker removal (P2.4) eliminates MLC's `extract_string_values` dependency in tree docs as well as single-record docs.
5. **PUI read path unchanged by ANW-2229.** ANW-2229 does not touch `record.rb` or the PUI display read path; MLC's locale-projection / language-header handling is MLC's own concern. There is no shared read-path helper to build here.
6. **Per-locale `qf` boost merges with P2.1 as named paramsets.** MLC's per-locale boost work (formerly MCTF §5.5 bullet 2) is folded into ANW-2229 P2.1. P2.1 moves all relevance configuration (`qf` / `pf` / `mm` / `tie`) out of Ruby and into Solr's named `<initParams>` parameter sets in `solrconfig.xml`. Per-locale boosts are paramsets named `qf_locale_<iso>_<script>` (e.g. `qf_locale_fre_Latn`); the backend appends them via `useParams=qf_default,qf_locale_fre_Latn` when the request carries a curated active locale. No per-request `qf`/`pf` strings.

### Sub-ticket impact

| ANW-2229 sub-ticket | MLC interaction | Adjustment to scope |
|---|---|---|
| P1.1 (indexer specs) | `mlc_fields`, per-language Solr fields, language-suffixed tree docs need fixtures with `lang_descriptions` to characterize | Add MLC-populated fixture variants for the 5 MLC-using record types (resource, accession, archival_object, digital_object, digital_object_component); assert `mlc_fields` shape, per-language emission, fan-out tree docs as currently shipped in PR #4046 |
| P1.3 (inventory) | Solr field map must enumerate `*_<iso>_mlc` and the 7 `text_<iso>` types | Add the MLC dynamic fields and field types to the Solr field map; flag the target search-field name (`*_<iso>_<script>_tesim`) in the disposition column |
| P2.1 (per-search-type `qf`) | MLC's per-locale boost work merges into this ticket | All relevance config (`qf` / `pf` / `mm` / `tie`) moves into named `<initParams>` paramsets in `solrconfig.xml`. Per-locale boosts become paramsets `qf_locale_<iso>_<script>` composed via `useParams=qf_default,qf_locale_<active>` |
| P2.2-P2.4 (per-note fields, `qf_default`, walker removal) | Per-language search fields must appear explicitly in `qf_default` (or in the per-locale paramsets that compose with it). No copyField glob; the source-field list is the contract. Replaces MLC's `extract_string_values` reliance | `qf_default` lists multilingual fields with their primary suffix (`title_primary_tesim`, etc.); the per-locale paramsets `qf_locale_<iso>_<script>` enumerate the per-language variants with locale-specific boosts. Adding an 8th curated language means adding one paramset, not editing every existing one |
| P2.5 (`identifier_match`) | Identifiers are not multilingual | No conflict |
| P2.6 (ICU + `mm`) | The 7 per-language analyzer chains apply to per-language `*_<iso>_<script>_tesim` fields. ICU + folding applies to the field type backing the generic `*_tesim` dynamic field. The two are independent | Preserve the 7 `text_<iso>` `<fieldType>` definitions and the `solr/lang/` files when restructuring schema; the new ICU-based `*_tesim` type is for non-multilingual text and for languages without curated chains |
| P2.7 (highlighting) | The `summary` may be built from a note in any language | Back the `summary` field with `text_icu` (ICU folding) so highlight tokenization works for non-Roman summaries; per-note-language analyzer refinement can come once MCTF §9 lands |
| P2.8 (filter correctness) | No interaction | No conflict |
| Out of scope X.1 (block-join) | Block-join's primary win is replacing `RecordInheritance.merge` and the ancestor-array denormalisation, not the multilingual collapse | Reframed: block-join is about ancestor inheritance, not languages |

### Migration sequencing

Coordinated landing order:

1. **ANW-2229 Phase 1** (P1.1 / P1.2 / P1.3) lands first. Characterization specs cover the as-merged PR #4046 state (`mlc_fields`, `*_<iso>_mlc` fields, per-language tree-doc fan-out). Inventory captures both projects' fields. Locks the contract for both.
2. **MLC search-field work** (successor to PR #4046, tracked under MCTF §5.6) lands the per-language searchable fields (`*_<iso>_<script>_tesim`, stored=true) and `_primary_tesim` companions. It does not need to coordinate on the JSON blob (retained) or remove `extract_string_values` (still ANW-2229's job).
3. **ANW-2229 Phase 2** (the relevance-query fixes) lands. P2.3 routes default keyword search to `qf_default` and P2.4 removes `extract_string_values` (no catchall). P2.1 enumerates the per-language fields and the per-locale boost paramsets in `solrconfig.xml`.

Each step lands in a self-consistent state. The reindex window is shared (one full reindex on the upgrade that ships steps 2 + 3).

## Scope of this branch: Phase 1 only

ANW-2229 is too large for one PR. **This branch lands Phase 1: spec foundation + inventory document definition.** **The target architecture is committed**: no search catchalls, dynamic-field suffixes for the new search fields, all relevance config via named `solrconfig.xml` paramsets enumerating their source fields directly, `identifier_match` field type, ICU folding on the `*_tesim` field type. The `json` display blob is retained. Phase 1 is written with that target in mind.

### Phase 1: Spec foundation & inventory document (this PR)

Goal: Cover current behaviour with [characterization tests](https://lassala.net/2026/02/09/characterization-tests-a-way-into-legacy-code/) so we can proceed confident into Phase 2; produce an inventory document to guide Phase 2 implementation.

**1. Indexer characterization specs** (assert current behaviour, do not change it)

- `indexer/spec/indexer_common_spec.rb`: one example per record type (resource, archival_object, accession, agent_person/corporate_entity/family/software, subject, digital_object, digital_object_component, classification, classification_term, top_container, location, repository, event, assessment). Assert populated Solr field set, primitive field values, and the **list of top-level keys present in `doc['json']`**.
- New spec covering `IndexerCommon.extract_string_values` directly. Per fixture, assert which strings land in `fullrecord_published` vs. `fullrecord`, making ANW-2657 / ANW-201 / ANW-1672 visible.
- `indexer/spec/pui_indexer_spec.rb`: cover the `RecordInheritance.merge` re-store path.
- `indexer/spec/large_tree_doc_indexer_spec.rb`: replace stubs with real assertions on `tree_root` / `tree_waypoint` / `tree_node`.
- New spec asserting plugin hooks (`add_indexer_initialize_hook`, `add_document_prepare_hook`, `add_extra_documents_hook`) are invoked on every record (`hello_world` plugin is a usable fixture).

**2. Public Record characterization specs**

- New `public/spec/models/record_spec.rb` and per-subclass specs in `public/spec/models/{resource,archival_object,digital_object,accession,agent,subject,classification,top_container,location}_spec.rb`. For a stub `solr_result` per type, assert which `@json[...]` keys the Record reads and what each accessor returns. Locks current PUI read behaviour as a regression baseline (the blob is retained, so this is a safety net, not a contract for an upcoming rewrite).
- Enumerate via `grep -n "@json\[\|json\[" public/app/models/*.rb public/app/controllers/*.rb`.

**3. Backend search query specs**

- Extend `backend/spec/model_solr_spec.rb`: for keyword / advanced / match-all entry points (`backend/app/model/search.rb:5-74`), assert `qf`, `pf`, `defType`, `mm` (currently absent), `fq` (suppressed/published), and facet shape sent to Solr.

**4. Inventory document**

Commit `docs/search_refactor_inventory.md` (path TBD per project convention). Two tables:

- **Solr field map**: every field in `solr/schema.xml`. Columns: name, type, indexed, stored, multivalued, writer file:line, readers file:line, Arclight equivalent, disposition (drop / keep / change-analyzer / new search field).
- **Linked-ticket → code path map**: for each linked ticket: file(s), field(s), and resolving phase. Makes Phase 2 ticket-cutting mechanical.

### Phase 2 (future tickets): relevance-query fixes

Phase 2 is eight sub-tickets, P2.1 through P2.8, each fixing a linked-ticket cluster with a direct Arclight precedent. They are specified in full under "Jira ticket breakdown" below (scope, dependencies, acceptance, closes). In outline: P2.1 builds the `solrconfig.xml` paramset infrastructure; P2.2-P2.4 add per-note-type search fields, route default keyword search to `qf_default`, and remove the `fullrecord` catchall; P2.5 adds the `identifier_match` field type; P2.6 adds the ICU analyzer, punctuation handling, and `mm`; P2.7 fixes highlighting; P2.8 fixes Creator / Level filter correctness.

## Verification (Phase 1)

All new specs must pass against unchanged production code; they characterise existing behaviour.

- `./build/run backend:test -Dspec="model_solr_spec.rb"`.
- Indexer specs: invocation per `build/build.xml`; confirm CI target before adding new files.
- `./build/run public:test -Dspec="models/record_spec.rb"` (and per-type specs).
- `./build/run rubocop` clean.
- Manual sanity: bring up Solr + backend + indexer, index a fixture resource, dump one Solr doc with `curl 'http://localhost:8090/solr/archivesspace/select?q=*:*&rows=1&wt=json'`, spot-check field set matches new spec assertions.
- Inventory review: every Solr field has writer + reader columns; every linked Jira ticket has a row.

## Verification (Phase 2)

Each Phase 2 PR is verified on a freshly reindexed dataset, against a multi-level resource (a collection with series / sub-series / file / item):

- **Collection Overview** (the resource show page) renders: title, notes, dates, agents, extents.
- **Collection Organization** (the hierarchical tree) renders: the tree expands, waypoints load, node levels display, and deep links to components resolve.
- Keyword search still returns the resource and its components; the linked-ticket reproduction for the PR's cluster passes.
- `./build/run public:test` feature specs covering the resource tree pass; add one if coverage is missing.

The tree path is retained by scope (see "Tree display (Collection Overview / Collection Organization) is unaffected"), so these checks are a regression guard, not a migration step.

## Jira ticket breakdown

**Epic structure.** ANW-2229 is the Epic (description, comments, attachments, ASRM-27 link preserved). Sub-tickets become children. Existing linked tickets stay in their current state and close individually as the Phase 2 children that fix them land.

**Sprint sizing.** Each sub-ticket is scoped to fit within one 3-week sprint; 🟡 marks a tight fit.

**Summary of sub-tickets** (11 total; create per "Pending Jira admin actions" below):

| Ticket | Title | Depends on | Closes | Sprint fit |
| --- | --- | --- | --- | --- |
| P1.1 | Indexer characterization specs | - | ANW-2229 spec deliverable | 🟡 1 |
| P1.2 | Public Record + backend Solr query specs | - | ANW-2229 spec deliverable | 1 |
| P1.3 | Search-refactor inventory document | - | ANW-2229 docs deliverable | 1 |
| P2.1 | Per-search-type `qf` paramsets in `solrconfig.xml` | Phase 1 | ANW-2656 | 🟡 1 |
| P2.2 | Emit per-note-type search fields (additive) | Phase 1 | (enabling step) | 1 |
| P2.3 | Route default search to `qf_default`; publish scoping | P2.1, P2.2 | ANW-2657, ANW-201, ANW-1672 | 🟡 1 |
| P2.4 | Remove `extract_string_values` + catchall fields | P2.3 | (catchall cleanup) | 1 |
| P2.5 | `identifier_match` field type + `qf_identifier` | P2.1 | ANW-290, ANW-1556, ANW-2071, ANW-2075 | 1 |
| P2.6 | ICU analyzer + punctuation stopwords + `mm` | P2.1 | ANW-1178, ANW-1686, ANW-308, ANW-859 | 1 |
| P2.7 | Highlight result-list summary + per-note highlights | P2.2, P2.6 | ANW-2315 | 🟡 1 |
| P2.8 | Filter correctness: published creators + level | Phase 1 | ANW-262, ANW-1580 | 1 |

One developer works these tickets sequentially. The table above is in suggested implementation order: the three Phase 1 tickets (any order between them), then Phase 2 as listed - P2.1 (paramset infrastructure) first, then the P2.2 → P2.3 → P2.4 chain, then P2.5, P2.6, P2.7, P2.8. The Depends-on column records the hard constraints; the listed order satisfies them all.

### Phase 1 sub-tickets (3)

**P1.1: Indexer characterization specs**

- Scope: `indexer/spec/indexer_common_spec.rb` covering all 17 record types. New direct spec for `extract_string_values`. `pui_indexer_spec.rb` for `RecordInheritance.merge` re-store. `large_tree_doc_indexer_spec.rb` real assertions on `tree_root` / `tree_waypoint` / `tree_node`. Plugin hook spec.
- Acceptance: all specs pass against unchanged code; rubocop clean.
- Closes: part of ANW-2229 spec deliverable.
- MLC: add fixture variants with `lang_descriptions` for the 5 MLC-using record types (resource, accession, archival_object, digital_object, digital_object_component); assert `mlc_fields` shape, `*_<iso>_mlc` per-language emission, and language-suffixed tree-doc fan-out as currently shipped in PR #4046 (see "MLC coordination" section).
- Sprint fit: 🟡 1 sprint.

**P1.2: Public Record + backend Solr query characterization specs**

- Scope: New `public/spec/models/record_spec.rb` + per-subclass specs for 9 PUI record types. Stub `solr_result` fixtures, assert `@json[...]` reads + accessor outputs. Extend `backend/spec/model_solr_spec.rb` for `qf`/`pf`/`defType`/`fq`/facet shape on keyword + advanced + match-all entry points.
- Acceptance: 9 PUI types covered; backend Solr specs lock current behaviour.
- Closes: part of ANW-2229 spec deliverable; regression baseline for the PUI read path (retained through this project).
- Sprint fit: 1 sprint.

**P1.3: Search-refactor inventory document**

- Scope: Commit `docs/search_refactor_inventory.md` with two tables (Solr field map, linked-ticket → code-path map).
- Acceptance: every Solr field has writer + reader columns; every linked ticket has a row.
- Closes: the Phase 1 inventory document (part of deliverable 1).
- MLC: Solr field map enumerates `*_<iso>_mlc` dynamic fields and the 7 `text_<iso>` field types; the disposition column flags the target search-field name `*_<iso>_<script>_tesim` (per MCTF §5.5.1).
- Sprint fit: 1 sprint.

### Phase 2 sub-tickets (8: implement in order, P2.1 first)

**P2.1: Per-search-type `qf` groups as `solrconfig.xml` paramsets**

- Depends on: Phase 1. **Foundation for P2.3, P2.5, P2.6**: those tickets all add to or modify the paramset enumeration.
- Scope: relevance configuration moves from Ruby string-building (`backend/app/model/solr.rb:345-350`) into Solr server-side **named parameter sets** (`<initParams>`) declared in `solrconfig.xml`. **No catchall**: each paramset's `qf` enumerates its source fields directly, and fields not enumerated in any paramset are not searchable by default. Define paramsets `qf_default` / `qf_identifier` / `qf_title` / `qf_name` / `qf_subject` / `qf_place` / `qf_container`, each carrying its own `qf` / `pf` / `mm` / `tie` configuration. `qf_default` lists the cross-record-type defaults (titles, identifiers, repository, dates, agents, subjects, primary-language note text); per-context paramsets specialise. Backend per-request work shrinks to selecting which paramset(s) apply via `useParams=<name>[,<name>...]`; no per-request `qf`/`pf` strings are sent. `backend/app/model/solr.rb` is rewritten to emit `useParams` based on search context (default keyword / identifier / linker type / advanced-search field). `frontend/app/views/{resources,agents,subjects,…}/_linker.html.erb` and `linker.js` propagate the linker type so the backend picks the right paramset. Arclight's `solrconfig.xml` is the direct precedent. Match-all browse queries (`Solr::Query.create_match_all_query`) and URI-lookup requests (`/search/records`, used for record show pages and tree-doc fetches) are **not** given `useParams` - paramset selection applies only to edismax keyword / identifier / linker requests, so match-all browse and tree fetching are unaffected.
- Acceptance: agent linker prioritises name hits; subject linker prioritises term hits; resource linker prioritises title + identifier; relevance changes ship by editing `solrconfig.xml` and reloading the core, no Ruby redeploy required; Solr response `params` echo confirms the merged paramset for each request.
- Closes: ANW-2656.
- MLC: per-locale boosts are additional paramsets named `qf_locale_<iso>_<script>` (e.g. `qf_locale_fre_Latn`) carrying the locale-specific field weights (`title_fre_Latn_tesim^3`, `finding_aid_title_fre_Latn_tesim^2`). The backend appends the locale paramset when the request carries an active locale matching one of the seven curated languages. `useParams=qf_default,qf_locale_fre_Latn` is the composed form. This absorbs the MCTF §5.5.5 per-locale `qf` boost work.
- Touches: `solr/solrconfig.xml` (paramset declarations), `backend/app/model/solr.rb` (paramset selection logic), `backend/spec/model_solr_spec.rb` (P1.2 spec assertions update from per-request `qf` strings to per-request `useParams` selections), `frontend/app/views/.../linker.html.erb` + `linker.js` (linker-type propagation).
- Sprint fit: 🟡 1 sprint.

The walker removal / `qf_default` routing work is too large for one sprint, so it is split into three sub-tickets that each land in a self-consistent state: P2.2 adds the new fields (additive), P2.3 moves search onto them, P2.4 removes the now-unused catchall.

**P2.2: Emit per-note-type search fields alongside the catchall**

- Depends on: Phase 1.
- Scope: rewrite `IndexerCommon.add_notes` (`indexer/app/lib/indexer_common.rb:268-274`) to emit, for each note type, a `<type>_tesim` field (published notes, markup stripped, `indexed=true stored=true` so the highlighter can use it) and a `<type>_unpublished_tesim` companion for staff-only content. No `*_html_tesm` display fields - note display continues to read the retained `json` blob. **Additive only**: the legacy `notes` / `notes_published` and the `fullrecord` / `fullrecord_published` catchall are left in place and still written, so search behaviour is unchanged. The indexer now writes both representations.
- Acceptance: spec asserts each note type emits a populated `<type>_tesim` (published) and `<type>_unpublished_tesim` (unpublished) field with markup stripped; the legacy `notes` / `notes_published` / `fullrecord` fields are still populated; default keyword search behaviour is unchanged.
- Closes: enabling step for P2.3 and P2.7; no linked ticket on its own.
- MLC: per-language note content is emitted into the per-language `*_<iso>_<script>_tesim` variants by the same `document_prepare_hook` (MCTF §5.5.2).
- Sprint fit: 1 sprint.

**P2.3: Route default keyword search to `qf_default`; move publish scoping off the parallel catchall**

- Depends on: P2.1 (paramset infrastructure), P2.2 (per-note-type fields exist).
- Scope: route default keyword search to the `qf_default` paramset (declared via `<initParams>` in `solrconfig.xml`, P2.1) whose `qf` enumerates the source fields explicitly, including the per-note-type `*_tesim` fields. `backend/app/model/solr.rb` selects `qf_default` and the per-context paramsets via `useParams` instead of building a `qf` over `fullrecord`. Publish-status handling is rebuilt without the parallel-field workaround: PUI search applies `fq=publish:1` for record-level scoping and its paramsets list only the published `<type>_tesim` fields; a staff search context opts into the `<type>_unpublished_tesim` variants. After this ticket nothing queries `fullrecord` / `fullrecord_published` / `notes` / `notes_published`, although those fields still exist in the index.
- Acceptance: spec asserts subject URIs / internal IDs / container labels / agent contacts / event-record IDs do NOT match a default keyword search; note text remains matchable via the per-note-type fields; PUI search returns no unpublished record or note content; manual reproduction of ANW-2657 / ANW-201 / ANW-1672 fails.
- Closes: ANW-2657, ANW-201, ANW-1672.
- MLC: per-language fields become searchable by appearing in `qf_default` (their primary-language counterpart) and in the `qf_locale_<iso>_<script>` paramsets. No copyField glob; the source-field list across paramsets is the contract.
- Sprint fit: 🟡 1 sprint.

**P2.4: Remove `extract_string_values` and the catchall fields**

- Depends on: P2.3 (search no longer touches the catchall).
- Scope: remove `IndexerCommon.extract_string_values` (`indexer/app/lib/indexer_common.rb:140-207`) and `IndexerCommon.build_fullrecord` (`:210-214`), and the PUI indexer's parallel `build_fullrecord` override (`indexer/app/lib/pui_indexer.rb:94-122`, which makes its own `extract_string_values` call). Drop the `fullrecord`, `fullrecord_published`, `notes`, and `notes_published` field declarations and the `notes_published`→`notes` `<copyField>` from `solr/schema.xml`. (`large_tree_doc_indexer.rb` needs no change - its `tree_root` / `tree_waypoint` / `tree_node` docs never call the walker.)
- Acceptance: the walker and the catchall fields are absent; a full reindex succeeds; index size after reindex is measurably smaller (catchall storage gone); the P2.3 search specs still pass.
- Closes: nothing on its own - ANW-2657 / ANW-201 / ANW-1672 are closed by P2.3; this ticket is the catchall-field cleanup.
- Sprint fit: 1 sprint (likely less).

**P2.5: `identifier_match` field type + `qf_identifier` paramset**

- Depends on: P2.1 (paramset infrastructure).
- Scope: new `identifier_match` field type in `solr/schema.xml` (WordDelimiterGraphFilter with `catenateWords=1 catenateNumbers=1 catenateAll=1`); the indexer emits identifier sub-parts into `identifier_match` for resources, archival objects, accessions, digital objects, and digital object components. New `qf_identifier` paramset (declared via `<initParams>` in `solrconfig.xml`) enumerates identifier-bearing fields directly with appropriate boosts: `id^4 ead_id^3 ref_id^3 component_id^3 digital_object_id^3 identifier_match^4 unitid_ssm^2`. No `identifier_search` catchall. `backend/app/model/solr.rb` routes identifier-context searches via `useParams=qf_identifier`.
- Acceptance: spec asserts multi-part IDs (e.g. `MS-2024-001` ↔ `MS2024001`) match in either catenation; advanced search "Identifier contains" passes for all flagged variants.
- Closes: ANW-290, ANW-1556, ANW-2071, ANW-2075.
- Sprint fit: 1 sprint.

**P2.6: ICU analyzer chain + punctuation stopwords + `mm`**

- Depends on: P2.1 (paramsets carry `mm`).
- Scope: introduce a new `text_icu` field type in `solr/schema.xml` based on `ICUTokenizerFactory` + `ICUFoldingFilterFactory`; redirect the `*_tesim` dynamic field declaration to use `text_icu` instead of `text_general`. Add a `string_punct_stop` field type for fields where `& : ; [ ]` should be treated as query-side stopwords (apply selectively). Set `mm=4<90%` on every paramset that drives a default-style keyword search (`qf_default`, `qf_title`, `qf_name`, etc.) so short queries require all terms and long queries require 90%.
- Acceptance: spec coverage for ASCII-folded + ICU-folded + non-Roman searches (Cyrillic, Arabic, Hebrew, Greek, CJK); punctuation queries no longer 500 or silently drop; `mm=4<90%` confirmed on every keyword-style paramset.
- Closes: ANW-1178, ANW-1686, ANW-308, ANW-859.
- MLC: preserve the 7 `text_<iso>` `<fieldType>` definitions and the `solr/lang/` stopword / contraction / stemdict files from MLC PR #4046 unchanged. They apply to per-language `*_<iso>_<script>_tesim` fields, independent of the new `text_icu` type backing the generic `*_tesim` suffix. Records in non-curated languages fall through to `text_icu` and benefit from ICU folding without language-specific stemming.
- Sprint fit: 1 sprint.

**P2.7: Highlight search terms in the result-list summary and per-note highlights**

- Depends on: P2.2 (emits the per-note-type `*_tesim` fields the highlights block highlights); P2.6 (so `summary` and the note fields share the `text_icu` analyzer; can ship earlier against `text_general` if needed).
- Scope:
  - **Summary highlighting.** `IndexerCommon.add_summary` (`indexer_common.rb:311-324`) is unchanged: same note-selection logic (first `abstract`, else first `scopecontent`), same `doc['summary']` content, same displayed summary. Change the `summary` field (`solr/schema.xml:45`) from `indexed="false"` to `indexed="true"` (keep `stored="true" multiValued="false"`), backed by a text analyzer aligned to the searchable note fields (`text_icu` once P2.6 lands) so highlight tokenization matches search tokenization. `summary` is added to no `qf` paramset - display-and-highlight only, never a search target, so it does not affect matching or scoring and is not a search catchall. The result-list summary partial (`shared/_result_record_summary.html.erb`, rendered from `_result.html.erb`) renders the highlighted `summary` from Solr's `highlighting` response when present, falling back to the plain stored value. Summary content, note selection, and placement are unchanged; the only visible difference is `<span class="searchterm">` wrappers.
  - **Per-note highlights section.** The separate highlights block in `public/app/views/shared/_result.html.erb` (lines 24-34) is driven by the per-note-type `*_tesim` search fields P2.2 emits, so it attributes a match to the exact note it came from ("Found in: Biographical/Historical Note: …"). **Only published notes are highlighted in the PUI**: the PUI `hl.fl` enumerates only the published per-note-type fields (`abstract_tesim`, `bioghist_tesim`, `scopecontent_tesim`, etc.); the `<type>_unpublished_tesim` companions are never placed in the PUI `hl.fl`, so unpublished note text cannot leak into a highlight snippet. (A staff search context may add the `_unpublished` fields to its own `hl.fl` if needed, consistent with P2.2's `_unpublished` design.)
  - **Highlighting config (`solrconfig.xml`).** Replace the `hl.fl=*` wildcard with an explicit `hl.fl` listing `summary` plus the published per-note-type `*_tesim` fields. `hl.method` may move from `original` to `unified` for offset accuracy; optional.
  - **Locales.** Add `search_results.highlighting.<note-type>` keys (`common/locales/en.yml`) so each per-note-type highlight renders a human-readable label; the `Translation missing` skip filter in `_result.html.erb` then no longer hides note-type highlights.
- Known limitation: a search term is highlighted in the `summary` only when it occurs in the note the summary was derived from (abstract or scopecontent); a match in any other published note does not appear in the summary but is surfaced by the per-note highlights block below it.
- Acceptance:
  - Spec: a search whose term appears in a record's abstract / scopecontent returns a `summary` highlight with the term wrapped in `<span class="searchterm">`; the `summary` text is otherwise identical to today's.
  - Spec: a search whose term appears in any published note returns a per-note highlight in the highlights section, attributed to that note type.
  - Spec: a search term that appears only in an unpublished note produces no PUI highlight; the `<type>_unpublished_tesim` fields are absent from the PUI `hl.fl`.
  - Spec: `IndexerCommon.add_summary` output is unchanged (the P1.1 characterization spec for it still passes).
  - Spec: `summary` is `indexed="true"`, appears in `hl.fl`, and appears in no `qf` paramset.
- Closes: ANW-2315.
- MLC: the `summary` may be built from a note in any language; backing it with `text_icu` (per the scope above) keeps highlight tokenization correct for non-Roman summaries. Per-note-language analyzer refinement can follow once MCTF §9 lands.
- Sprint fit: 🟡 1 sprint (summary highlighting + per-note highlights + locales).

**P2.8: Filter correctness: published creators + consistent level field**

- Depends on: Phase 1.
- Scope: Indexer adds `published_creators` (only published linked agents in creator role). `level` collapses its three writers (`indexer_common.rb:306, 529, 549`) into a single source of truth with consistent `otherlevel → other_level` substitution. Backend routes Creator + Level facet filters to the new fields.
- Acceptance: PUI Creator filter excludes records whose only matching creator is unpublished; level facet matches displayed level.
- Closes: ANW-262, ANW-1580.
- Sprint fit: 1 sprint.

## Critical files

**Indexer (writes Solr):**

- `solr/schema.xml`: current schema. Line 44 is the `json` display blob field (retained).
- `indexer/app/lib/indexer_common.rb`
  - `:140-207` `extract_string_values`: naive tree walker producing `fullrecord` content (removed in P2.4).
  - `:210-214` `build_fullrecord`: caller (removed in P2.4).
  - `:268-274` `add_notes`: calls the walker; rewritten in P2.2 to emit per-note-type `*_tesim` fields.
  - `:1235-1254` `sanitize_json`: strips agent contacts before serialising the blob (unchanged).
  - `:1256-1321` `index_records`: main per-record loop. Line 1280 is the `doc['json'] = …` site (unchanged).
  - `:52-83`, `:1034`, `:1039`: `add_indexer_initialize_hook`, `add_document_prepare_hook`, `add_extra_documents_hook`: plugin extension API to preserve.
- `indexer/app/lib/{periodic_indexer,pui_indexer,large_tree_doc_indexer}.rb`: callers/specialisations.

**Search (reads Solr):**

- `backend/app/model/solr.rb`: `Solr::Query` (98–387). `qf`/`pf`/edismax config at 345–350.
- `backend/app/model/search.rb`: keyword/advanced/match-all entry points.
- `backend/app/controllers/search.rb`: REST endpoints.

**JSON-blob consumers (retained as-is, not modified by this project):**

- `public/app/models/record.rb:19-25`: `@json = ASUtils.json_parse(solr_result['json'])`.
- `public/app/models/solr_results.rb:6-46`: wrapper handing raw Solr hits to `Record.new`.
- `public/app/controllers/{agents,objects,repositories}_controller.rb`, plus PUI models `classification.rb`, `accession.rb`, `resource.rb`: secondary consumers.
- `public/app/services/archives_space_client.rb`: `get_raw_record` fetches records (including the `tree_root` / `tree_waypoint` / `tree_node` tree docs) by URI via `/search/records` and parses their `json` field.
- `public/app/views/shared/_result.html.erb` and `shared/_result_record_summary.html.erb`: P2.7 makes the summary partial render the highlighted `summary` and drives the highlights block (`_result.html.erb` lines 24-34) from the published per-note-type `*_tesim` fields; the partials' blob reads are untouched.
- Frontend (staff) does not parse `doc['json']` directly.

**Tests (current coverage is thin):**

- `indexer/spec/indexer_common_spec.rb` (≈81 lines): published/unpublished text separation only.
- `indexer/spec/{periodic,pui}_indexer_spec.rb`: light integration coverage.
- `indexer/spec/large_tree_doc_indexer_spec.rb`: stub bodies, no assertions.
- `backend/spec/model_solr_spec.rb`: basic smoke tests.
- No spec covers `record.rb`'s reliance on `solr_result['json']` or `extract_string_values` directly.

### Out of scope

- 🔴 **X.1: Block-join hierarchy migration.** `_root_` / `_nest_parent_` / `_nest_path_` to drop `RecordInheritance.merge` and the ancestor-array denormalisation on every component doc, with optional knock-on simplification of `large_tree_doc_indexer`'s waypoint hack. Multi-sprint; needs spike + design doc; reframe as its own Epic.
- **X.2: ANW-902** (PUI indexer occasionally drops AOs from new EADs). Separate investigation; likely race / transaction-boundary bug.
- **X.3: Minor PUI tickets to re-evaluate after Phase 2**: ANW-1102, ANW-862, ANW-1628. Reassess against new schema before scoping.
- **X.4: Drop the JSON display blob.** Replacing the blob with explicit per-field stored display fields and rewriting `public/app/models/record.rb` was an earlier deliverable of this epic; it has been removed from scope. The blob is retained. If revisited, it is a separate effort.

### Pending Jira admin actions (run after plan approval, before sub-tickets are created)

1. ~~**Convert ANW-2229 from Task → Epic.**~~ ✅ Done.
2. ~~**Apply cluster-prefix titles** to the four multi-ticket clusters (Unexplainable matches, Identifier search, Analyzer chain, Filter correctness).~~ ✅ Done. 16 tickets renamed (ANW-2657, ANW-1672, ANW-201; ANW-290, ANW-1556, ANW-2071, ANW-2075; ANW-308, ANW-1686, ANW-859, ANW-1178; ANW-262, ANW-1580, ANW-1102, ANW-862, ANW-1628). The three single-ticket clusters (Highlighting / ANW-2315, Typeahead / ANW-2656, Indexer reliability / ANW-902) were not prefix-renamed.
3. **Create the 11 sub-tickets** from the breakdown above (P1.1, P1.2, P1.3; P2.1, P2.2, P2.3, P2.4, P2.5, P2.6, P2.7, P2.8) with `Epic Link = ANW-2229`.
