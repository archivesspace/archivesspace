# ANW-2229: Refactoring search logic

## Context

Jira: <https://archivesspace.atlassian.net/browse/ANW-2229> ("Refactoring our search logic"). Status: Ready for Implementation. Implements roadmap idea **ASRM-27**. Acceptance: a complete reindex on upgrade is acceptable.

Two deliverables:

1. **Add spec coverage.**
2. **Refactor the Solr schema: stop using huge JSON fields to represent all published data of records.**
3. **Fix a series of issues that are caused by our current poor usage of solr**

### Linked-ticket clusters (motivation)

The linked tickets cluster into themes the current architecture makes hard to fix correctly:

- **Identifier search**: ANW-290, ANW-1556, ANW-2071, ANW-2075. IDs are buried in the JSON blob; partial / multi-part / "contains" semantics are broken. Multi-part identifiers like `MS-2024-001` don't match `MS2024001` or `MS 2024 001`; advanced search "Identifier contains" misses obvious substring matches; users typing a known catalogue number don't always find the record. **Fixed in P3.2** by adopting Arclight's `identifier_match` field type (WordDelimiterGraphFilter with `catenateAll=1`, which generates concatenated token variants at index time so any catenation matches any other), and by defining a `qf_identifier` paramset in `solrconfig.xml` that enumerates every identifier-bearing field (`id`, `ead_id`, `ref_id`, `component_id`, `digital_object_id`, `identifier_match`, `unitid_ssm`) with appropriate boosts; the identifier-context paramset is invoked via `useParams=qf_identifier`.
- **Unexplainable matches**: ANW-2657 (subject/term URIs in PUI hits), ANW-201 (top-container info leaks), ANW-1672 (agent contacts/events appear). All caused by `IndexerCommon.extract_string_values` (`indexer/app/lib/indexer_common.rb:140-207`) walking the entire record JSON and concatenating every string into `fullrecord_published`/`fullrecord`. The walker is type-blind, so URIs (`/subjects/45`), internal IDs, staff-only metadata, top-container barcodes, and agent contacts all flow into the search index alongside genuine content; researchers get hits they can't account for from any visible field on the record. **Fixed in P3.1** by removing the walker entirely (along with the `fullrecord` and `fullrecord_published` synthetic fields it produced) and routing default keyword search to a `qf_default` paramset in `solrconfig.xml` whose `qf` enumerates the source fields explicitly. Fields not listed in any paramset's `qf` are not searchable by default; URIs / internal IDs / staff-only fields are excluded by omission (a finite, reviewable allow-list instead of an unbounded deny-list).
- **Analyzer chain**: ANW-308 (brackets), ANW-1686 (ampersands), ANW-859 (partial matches), ANW-1178 (non-Roman scripts). Driven by the `text_general` analyzer in `solr/schema.xml` and the lack of per-field tokenization choices. The stock analyzer silently drops bracket characters (so `[2024]` becomes searchable as `2024` with no way to query the literal brackets), breaks facet-filter URLs on ampersands, defaults to `mm=1` (minimum should match = any-term) so multi-term queries return weak partial matches, and has no Unicode folding for Cyrillic / Arabic / Hebrew / Greek / CJK scripts. **Fixed in P3.3** by switching the field type backing `*_tesim` dynamic fields to `ICUTokenizerFactory` + `ICUFoldingFilterFactory` (covers all Unicode scripts), adding a `string_punct_stop` field type to treat `& : ; [ ]` as query-side stopwords where appropriate, and setting `mm=4<90%` (1-4 terms: all required; 5+ terms: 90%) on every paramset so short queries require all terms and long queries require 90%; the seven MLC per-language analyzer chains (PR #4046) apply to per-language `*_<iso>_<script>_tesim` fields independently.
- **Highlighting / display**: ANW-2315 (note hits not highlighted in summary). `summary` is derived separately from `notes`, so highlighting doesn't carry across. When a keyword search matches a scope or biographical note, the result list shows a `summary` snippet computed from a different source (often a truncated abstract or the first N characters of scope content), so the matched word isn't visible in the snippet and users see hits with no apparent reason. **Fixed in P3.5** by deriving `summary` from the same analyzer output as `notes_published`, configuring Solr's highlighter against `notes_published`, and rendering the highlighted snippet inline with the result-list summary in the PUI.
- **Filter correctness**: ANW-262 (PUI Creator filter includes unpublished creators), ANW-1580 (level facet inaccurate), ANW-1102, ANW-862, ANW-1628. The `creator` field conflates published and unpublished agents so filtering by Creator returns records whose only matching creator is unpublished (a privacy-relevant defect, since a researcher should never see references to suppressed agents). The `level` field is written by three separate code paths (`indexer_common.rb:306, 529, 549`) with inconsistent `otherlevel → other_level` substitution, so facet counts diverge from the level displayed on each record. **Fixed in P3.6** by adding `published_creators` as a separate stored field (only published linked agents in creator role) and collapsing the three level writers into one with consistent substitution across resource / archival_object / digital_object; the backend routes Creator and Level facet filters to the new fields. ANW-1102 / ANW-862 / ANW-1628 are reassessed against the new schema after P3.6 lands; they may close trivially or need a small follow-up.
- **Indexer reliability**: ANW-902 (PUI indexer occasionally drops AOs from new EADs). Symptom: components from a freshly imported EAD don't appear in PUI search until the next periodic reindex, suggesting a race condition or transaction-boundary bug in the incremental-update path. Not driven by schema shape, so handled separately as parking-lot X.2 rather than within an ANW-2229 phase.
- **Typeahead relevancy**: ANW-2656. Linker typeaheads (Agent picker, Subject picker, Resource picker) don't prioritise the right fields: searching for "Smith" in the Agent linker returns records where "Smith" appears in notes, biographies, or addresses *before* records where "Smith" is the actual agent name, because the global `qf` weights titles and identifiers but not name fields specifically. **Fixed in P3.4** by defining per-search-type `qf` paramsets in `solrconfig.xml` (`qf_name`, `qf_subject`, `qf_title`, etc.) and propagating the linker type through to the backend (`linker.html.erb` + `linker.js`) so the right paramset applies: the Agent linker uses `qf_name` (prioritises name fields over notes), the Subject linker uses `qf_subject`, the Resource linker uses `qf_title` plus identifier weighting.

### Structural framing

- The schema **already has dedicated indexed fields** for most things (`title`, `identifier`, `notes`, `notes_published`, `agents`, `creators`, `subjects`, `dates`, `extents`, `langcode`, `level`: `solr/schema.xml:4-150`). The `json` blob (`schema.xml:44`) is **redundant for searching**: it exists almost entirely for **deserialization in the public UI** (`public/app/models/record.rb:19-25`).
- `fullrecord` is built by a **type-blind tree walk** (`indexer_common.rb:140-207`) that grabs every string in the record, including URIs and internal IDs.

### The serialize / deserialize pattern

The indexer serializes each record to a JSON string at `indexer_common.rb:1280` (`doc['json'] = ASUtils.to_json(sanitize_json(values))`). On every search hit the public UI deserializes that string at `public/app/models/record.rb:19-25` (`@json = ASUtils.json_parse(solr_result['json'])`); ~480 lines of `record.rb` and per-type subclasses then read `@json[...]` directly.

The blob is `indexed="false"`. Its sole purpose is letting **one** Solr request carry enough data to render result lists and show pages without N backend lookups. **Solr is the PUI's read database**: `public/app/services/archives_space_client.rb` reads record content exclusively through three Solr-backed endpoints (`/search`, `/search/records`, `/search/published_tree`). The only direct PUI→backend traffic that bypasses Solr is slug resolution and login. So phase 2 must replace the blob with **explicit per-field stored Solr fields**, not with backend calls.

### What "unexplainable matches" means

A researcher types `45`, gets resource X, opens it, and sees no `45` anywhere in title / notes / dates / agents. The match is real: `45` appeared in a subject URI like `/subjects/45`, a top-container barcode, or an internal event ID, all swept into the searchable text by `extract_string_values`. ANW-2657 / ANW-201 / ANW-1672 are three flavours of the same root cause. P3.1 fixes this by removing the walker and routing default keyword search to the `qf_default` paramset in `solrconfig.xml`, whose `qf` enumerates the searchable source fields explicitly; fields not listed (URIs, internal IDs, staff-only metadata) are excluded by omission rather than by mid-walk filtering.

### So "stop using the huge JSON field" is two related problems

- **(A)** Replace the deserialization pathway so the public UI no longer needs `doc['json']`, breaking the coupling at `public/app/models/record.rb`.
- **(B)** Replace the whole-record text-walker with a deliberate, per-field, per-record-type indexing strategy that fixes the unexplainable-match / analyzer / filter bugs.

The ticket scopes (A) explicitly. (B) is the natural next step that the linked bug tickets require.

## Critical files

**Indexer (writes Solr):**

- `solr/schema.xml`: current schema (220 lines). Lines 44, 78–79 are the JSON blob fields.
- `indexer/app/lib/indexer_common.rb`
  - `:140-207` `extract_string_values`: naive tree walker producing `fullrecord` content.
  - `:210-214` `build_fullrecord`: caller.
  - `:1235-1254` `sanitize_json`: strips agent contacts before serialising.
  - `:1256-1321` `index_records`: main per-record loop. Line 1280 is the `doc['json'] = …` site.
  - `:52-83`, `:1034`, `:1039`: `add_indexer_initialize_hook`, `add_document_prepare_hook`, `add_extra_documents_hook`: plugin extension API to preserve.
- `indexer/app/lib/{periodic_indexer,pui_indexer,large_tree_doc_indexer}.rb`: callers/specialisations. PUI indexer at `:83-88` re-merges with `RecordInheritance` and re-stores `json`.

**Search (reads Solr):**

- `backend/app/model/solr.rb`: `Solr::Query` (98–387). `qf`/`pf`/edismax config at 345–350.
- `backend/app/model/search.rb`: keyword/advanced/match-all entry points.
- `backend/app/controllers/search.rb`: REST endpoints.

**JSON-blob consumers (the breakable surface):**

- `public/app/models/record.rb:19-25`: `@json = ASUtils.json_parse(solr_result['json'])`. Single biggest tight-coupling point.
- `public/app/models/solr_results.rb:6-46`: wrapper handing raw Solr hits to `Record.new`.
- `public/app/controllers/{agents,objects,repositories}_controller.rb`, plus PUI models `classification.rb`, `accession.rb`, `resource.rb`: secondary consumers.
- `public/app/services/archives_space_client.rb:115`: reads `tree_json`.
- Frontend (staff) does not parse `doc['json']` directly.

**Tests (current coverage is thin):**

- `indexer/spec/indexer_common_spec.rb` (≈81 lines): published/unpublished text separation only.
- `indexer/spec/{periodic,pui}_indexer_spec.rb`: light integration coverage.
- `indexer/spec/large_tree_doc_indexer_spec.rb`: stub bodies, no assertions.
- `backend/spec/model_solr_spec.rb`: basic smoke tests.
- No spec covers `record.rb`'s reliance on `solr_result['json']` or `extract_string_values` directly.

## Reference: how Arclight does it

Arclight (`projectblacklight/arclight`) is the closest active reference: Blacklight-based discovery for EAD-described archival material. Patterns worth borrowing:

1. **No JSON blob, period.** Display fields are individual stored fields (`abstract_html_tesm`, `scopecontent_html_tesm`, `extent_ssm`, `creator_ssim`). Replaces `solr_result['json']` parsing.
2. **Blacklight dynamic-field suffix convention.** Each suffix encodes (type, stored, indexed, multivalued) so the schema becomes self-documenting. Decoded left-to-right after the underscore:

   | Position    | Letters                             | Meaning                                                                        |
   | ----------- | ----------------------------------- | ------------------------------------------------------------------------------ |
   | Type        | `t` / `te` / `s` / `i` / `dt` / `b` | text / text-English-analyzed / string (untokenized) / integer / date / boolean |
   | Stored      | `s`                                 | returned in search results                                                     |
   | Indexed     | `i`                                 | searchable / facetable / sortable                                              |
   | Multivalued | `m`                                 | array, not scalar                                                              |

   The four suffixes Phase 2 will use most:

   - **`_tesim`**: text-English, stored, indexed, multivalued. Full-text-searchable display content (note bodies, titles, abstracts).
   - **`_ssim`**: string, stored, indexed, multivalued. Untokenized exact-match: facetable values (creators, subjects, languages, levels).
   - **`_ssm`**: string, stored, multivalued (*not* indexed). Display-only strings.
   - **`_html_tesm`**: `html_` is a semantic prefix signalling "HTML payload"; body is text-English, stored, multivalued (*not* indexed). Display HTML for notes.

   The `_html_tesm` + `_tesim` pair is Arclight's standard for notes: emit one HTML copy (stored, for display) and one plain-text copy (indexed, for search). See `arclight/lib/arclight/traject/ead2_config.rb:242-248`. Other suffixes you'll see: `_si` (string indexed scalar), `_isi` (integer stored indexed scalar), `_isim` (integer stored indexed multivalued, used for date ranges), `_dtsim` (date stored indexed multivalued).
3. **No catchall, no tree walker; default search routes to a paramset enumerating its source fields directly.** Arclight does have a `text` catchall populated via `<copyField>` (Arclight `schema.xml:376-402`), but our plan goes one step further: instead of catchall + paramsets, we use paramsets only. The `qf_default` paramset's `qf` enumerates the source fields. Adding a field to default search means editing one paramset; URIs / internal IDs / staff fields are excluded by being absent from every paramset's `qf`. Direct fix for ANW-2657, ANW-201, ANW-1672 with the same allow-list semantics, no synthetic field, no copyField.
4. **Specialized identifier field types via paramset.** `identifier_match` (Arclight `schema.xml:175-195`) uses `WordDelimiterGraphFilterFactory` with `catenateAll=1` so multi-part IDs match in any catenation. We adopt the field type and route identifier-context searches via a `qf_identifier` paramset that enumerates `id`, `ead_id`, `ref_id`, `component_id`, `digital_object_id`, `identifier_match`, `unitid_ssm` directly (no `identifier_search` copyField catchall, same logic as point 3). Direct fix for the Identifier-search cluster.
5. **Per-field analyzer choices.** `text_en` (stemming + synonyms), an ICU-based field type for `*_tesim` (ICU tokenizer + ICU folding), `string_punct_stop` (treats `& : ;` as query-side stopwords). Direct fix for the Analyzer-chain cluster.
6. **Block-join nested docs for the collection/component hierarchy** (`_root_`, `_nest_parent_`, `_nest_path_`). Would let us drop `RecordInheritance.merge` and the `large_tree_doc_indexer` waypoint hack. Phase 3 evaluation candidate.
7. **Field-specific search handlers via named paramsets.** `qf_identifier` / `pf_identifier` / `qf_name` / `qf_place` / `qf_subject` / `qf_title` / `qf_container` declared as `<initParams>` blocks in `solrconfig.xml`, invoked from the controller via the `useParams=<name>[,<name>...]` request parameter (composable for layered configurations like locale boosts on top of a default). ArchivesSpace currently builds a single `qf` string in Ruby and tacks it onto every request (`backend/app/model/solr.rb:345-350`); the proposed shape moves all relevance configuration into `solrconfig.xml` and the per-request work shrinks to picking paramset names. Cheaper to tune (no Ruby redeploy), easier to audit (one file), composable.
8. **`mm=4<90%`**: minimum-should-match. ArchivesSpace's edismax has no `mm` set today. Affects ANW-859.
9. **Suggester + spellcheck wired to a curated list of source fields directly** (no catchall to draw from). Phase 3 candidate; the source-field list mirrors the `qf_default` paramset's enumeration.

**What does not carry over:** Arclight indexes from EAD XML via Traject (ArchivesSpace indexes resolved JSON via `IndexerCommon`); Arclight is read-only on Solr (ArchivesSpace's frontend writes via the backend); Arclight has no plugin hook surface, and ours must be preserved.

**Net effect:** phase 2 follows Blacklight `*_tesim` / `*_ssim` / `*_ssm` suffixes. Phase 3 bug-cluster fixes have direct Arclight precedents.

## MLC coordination (ANW-2282 / MCTF)

The Multilingual Content (MLC) project (epic ANW-2282 / Jira project MCTF) overlaps this refactor in indexing and search. Two MLC PRs are in flight: PR #3994 lays the `_mlc` MySQL tables and the `MultilingualContent` mixin; [PR #4046](https://github.com/archivesspace/archivesspace/pull/4046) adds the indexing plumbing. Neither has merged to master yet. The MLC plan is at `mctf_implementation_plan.md` (on the `ANW-2282-mlc-backwards-compatible` branch); the bits that touch this refactor are in §5.

Both projects need to land coordinated changes to `solr/schema.xml`, `indexer/app/lib/indexer_common.rb`, `indexer/app/lib/large_tree_doc_indexer.rb`, and `backend/app/model/solr.rb`. Rather than have either project complete first and the other retrofit, the two are unified on a single Solr field-naming convention and a single PUI read path. The unified design is documented in **MCTF plan §5.5**; the summary that follows captures only what affects ANW-2229 sub-tickets.

### Unified design summary

1. **One field-naming convention.** Every multilingual field on every record (single-record docs and tree-node docs alike) becomes `<field>_<iso>_<script>_tesim` (indexed AND stored, multivalued), with a `<field>_primary_tesim` companion populated from the record's primary language. Non-multilingual fields use plain Blacklight suffixes (`creator_ssim`, `identifier_ssim`, etc.). The 7 curated `<fieldType>` definitions (`text_eng`, `text_spa`, `text_fre`, `text_jpn`, `text_ger`, `text_ukr`, `text_dut`) and the `solr/lang/` stopword / contraction / stemdict files from MLC PR #4046 are kept unchanged.
2. **No catchall; default search via paramset enumeration.** `IndexerCommon.extract_string_values` and the synthetic `fullrecord` / `fullrecord_published` fields are removed (this refactor's P3.1). Default keyword search routes to a `qf_default` paramset whose `qf` enumerates the source fields directly, including per-language variants per record type. Per-locale paramsets (`qf_locale_<iso>_<script>`) layer locale-aware boosts on top via `useParams=qf_default,qf_locale_<active>`. MLC's reliance on the walker to funnel `mlc_fields` into `fullrecord` (MCTF §5.3) goes away with the walker; per-language fields enter the search index directly via the indexer's `document_prepare_hook`.
3. **No JSON blob, no `mlc_fields` in Solr.** The `mlc_fields` JSON key remains in the indexer-input record JSON (built by `MultilingualContent::ClassMethods.attach_mlc_fields_to_jsons!`), but is stripped from the doc before send. Per-language data lives in named Solr fields. Same logic as P2.3's `doc['json']` removal.
4. **Tree docs collapsed.** PR #4046 introduced per-language tree-doc fan-out (one full doc set per declared language, URI-suffixed `/<lang_tag>`). The unified design replaces it with one tree-doc set per tree, every node carrying every-language fields. Backend tree controllers drop the `description_language=<tag>` query parameter; `large_tree.rb` drops `with_description_language`; PUI projects the active locale at fetch time. See MCTF §5.5.3.
5. **PUI reads stop sending the language header.** The `X-ArchivesSpace-Description-Language` header still ships on writes (the mixin's setter routes writes to the right `_mlc` row based on `RequestContext`). PUI reads stop sending it once they read named fields directly (P2.2). Single-record show pages and tree fetches share one locale-projection helper.
6. **Per-locale `qf` boost merges with P3.4 as named paramsets.** MLC's per-locale boost work (formerly MCTF §5.5 bullet 2) is folded into ANW-2229 P3.4. P3.4 moves all relevance configuration (`qf` / `pf` / `mm` / `tie`) out of Ruby and into Solr's named `<initParams>` parameter sets in `solrconfig.xml`. Per-locale boosts are paramsets named `qf_locale_<iso>_<script>` (e.g. `qf_locale_fre_Latn`); the backend appends them via `useParams=qf_default,qf_locale_fre_Latn` when the request carries a curated active locale. No per-request `qf`/`pf` strings.

### Sub-ticket impact

| ANW-2229 sub-ticket | MLC interaction | Adjustment to scope |
|---|---|---|
| P1.1 (indexer specs) | `mlc_fields`, per-language Solr fields, language-suffixed tree docs need fixtures with `lang_descriptions` to characterize | Add MLC-populated fixture variants for the 5 MLC-using record types (resource, accession, archival_object, digital_object, digital_object_component); assert `mlc_fields` shape, per-language emission, fan-out tree docs (as currently shipped in PR #4046; the collapsed shape lands in MCTF §5.6) |
| P1.3 (inventory) | Solr field map must enumerate `*_<iso>_mlc` and the 7 `text_<iso>` types; JSON-blob consumer map must include `mlc_fields` | Add MLC rows to both maps; flag the post-rename target field name (`*_<iso>_<script>_tesim`) in the disposition column |
| P2.1 (stored fields) | Per-language stored fields (`<field>_<iso>_<script>_tesim`) align with the unified design | Coordinate the field-name list with MCTF §5.6 schema-rename pass; emit blob and named fields in parallel during the migration window |
| P2.2 (PUI rewrite) | PUI per-locale read path is shared between this work and MCTF §5.5.4 | One locale-projection helper covers both the cross-language refactor and the MLC active-locale read; build it once |
| P2.3 (drop blob) | The scalar-overwrite step in `attach_mlc_fields_to_jsons!` becomes obsolete once scalar fields no longer ship to Solr; coordinate the removal | When P2.3 lands, MCTF §5.6 removes step 4 of `attach_mlc_fields_to_jsons!` in the same PR (or the next one) |
| P3.1 (paramset enumeration replaces walker) | Per-language fields must appear explicitly in `qf_default` (or in the per-locale paramsets that compose with it). No copyField glob; the source-field list is the contract. Replaces MLC's `extract_string_values` reliance | `qf_default` lists multilingual fields with their primary suffix (`title_tesim`, `finding_aid_title_tesim`, etc.); the per-locale paramsets `qf_locale_<iso>_<script>` enumerate the per-language variants with locale-specific boosts. Adding an 8th curated language means adding one paramset, not editing every existing one |
| P3.2 (`identifier_match`) | Identifiers are not multilingual | No conflict |
| P3.3 (ICU + `mm`) | The 7 per-language analyzer chains apply to per-language `*_<iso>_<script>_tesim` fields. ICU + folding applies to the field type backing the generic `*_tesim` dynamic field. The two are independent | Preserve the 7 `text_<iso>` `<fieldType>` definitions and the `solr/lang/` files when restructuring schema; the new ICU-based `*_tesim` type is for non-multilingual text and for languages without curated chains |
| P3.4 (per-search-type `qf`) | MLC's per-locale boost work merges into this ticket | All relevance config (`qf` / `pf` / `mm` / `tie`) moves into named `<initParams>` paramsets in `solrconfig.xml`. Per-locale boosts become paramsets `qf_locale_<iso>_<script>` composed via `useParams=qf_default,qf_locale_<active>`; documented in MCTF §5.5.5 |
| P3.5 (highlighting) | Notes are MCTF §9 (per-note `language` + `script` attributes; not in `mlc_fields`) | No direct conflict; leave room for highlighting per-note-language once MLC §9 lands |
| P3.6 (filter correctness) | No interaction | No conflict |
| Parking lot X.1 (block-join) | Block-join's primary win is replacing `RecordInheritance.merge` and the ancestor-array denormalisation, not the multilingual collapse (which the unified design handles via per-language fields per doc, no block-join required) | Reframed: block-join is about ancestor inheritance, not languages |

### Migration sequencing

Three coordinated PRs, in this order:

1. **ANW-2229 Phase 1** (P1.1 / P1.2 / P1.3) lands first. Characterization specs cover the as-merged PR #4046 state (`mlc_fields`, `*_<iso>_mlc` indexed-only fields, per-language tree-doc fan-out). Inventory captures both projects' fields. Locks the contract for both.
2. **MLC schema-rename PR** (a successor to PR #4046, tracked under MCTF §5.6). Switches `*_<iso>_mlc` to `*_<iso>_<script>_tesim` (stored=true), adds `_primary_tesim` companions, collapses tree-doc fan-out, drops `description_language` query parameter. Does not yet drop the JSON blob or remove `extract_string_values` (those are still ANW-2229's job).
3. **ANW-2229 Phase 2 + Phase 3** as planned. P2.1's stored fields are already there from step 2 for MLC-using types; P2.1 just adds the rest. P2.2's PUI rewrite uses the same locale-projection helper for everything. P3.1 removes `extract_string_values` and routes default keyword search to a `qf_default` paramset (no catchall). P3.4 absorbs the per-locale `qf` boost as named `<initParams>` paramsets in `solrconfig.xml`, accessed via `useParams=`.

Each step lands in a self-consistent state; no PR depends on a future PR for correctness. The reindex window is shared (one full reindex on the upgrade that ships steps 2 + 3).

## Scope of this branch: Phase 1 only

ANW-2229 is too large for one PR. **This branch lands Phase 1: spec foundation + inventory document definition.** **The target architecture is committed: Blacklight-flavoured conventions** (no JSON blob, dynamic-field suffixes, no catchall, all relevance config via named `solrconfig.xml` paramsets enumerating their source fields directly, `identifier_match` field type, ICU folding on the `*_tesim` field type, block-join nesting under evaluation). Phase 1 is written with that target in mind.

### Phase 1: Spec foundation & inventory document(this PR)

Goal: Cover current behaviour with [characterization tests](https://lassala.net/2026/02/09/characterization-tests-a-way-into-legacy-code/) so we can proceed confident in phase 2; produce an inventory document to guide phase-2/3 implementation.

**1. Indexer characterization specs** (assert current behaviour, do not change it)

- `indexer/spec/indexer_common_spec.rb`: one example per record type (resource, archival_object, accession, agent_person/corporate_entity/family/software, subject, digital_object, digital_object_component, classification, classification_term, top_container, location, repository, event, assessment). Assert populated Solr field set, primitive field values, and the **list of top-level keys present in `doc['json']`**.
- New spec covering `IndexerCommon.extract_string_values` directly. Per fixture, assert which strings land in `fullrecord_published` vs. `fullrecord`, making ANW-2657 / ANW-201 / ANW-1672 visible.
- `indexer/spec/pui_indexer_spec.rb`: cover the `RecordInheritance.merge` re-store path.
- `indexer/spec/large_tree_doc_indexer_spec.rb`: replace stubs with real assertions on `tree_root` / `tree_waypoint` / `tree_node`.
- New spec asserting plugin hooks (`add_indexer_initialize_hook`, `add_document_prepare_hook`, `add_extra_documents_hook`) are invoked on every record (`hello_world` plugin is a usable fixture).

**2. Public Record characterization specs**

- New `public/spec/models/record_spec.rb` and per-subclass specs in `public/spec/models/{resource,archival_object,digital_object,accession,agent,subject,classification,top_container,location}_spec.rb`. For a stub `solr_result` per type, assert which `@json[...]` keys the Record reads and what each accessor returns. Locks the contract phase 2 must preserve.
- Enumerate via `grep -n "@json\[\|json\[" public/app/models/*.rb public/app/controllers/*.rb` plus `archives_space_client.rb:115` (`tree_json`).

**3. Backend search query specs**

- Extend `backend/spec/model_solr_spec.rb`: for keyword / advanced / match-all entry points (`backend/app/model/search.rb:5-74`), assert `qf`, `pf`, `defType`, `mm` (currently absent), `fq` (suppressed/published), and facet shape sent to Solr.

**4. Inventory document**

Commit `docs/search_refactor_inventory.md` (path TBD per project convention). Three tables:

- **Solr field map**: every field in `solr/schema.xml`. Columns: name, type, indexed, stored, multivalued, writer file:line, readers file:line, Arclight equivalent, phase-2 disposition (drop / rename / keep / change-analyzer).
- **JSON-blob consumer map**: every top-level key inside `doc['json']` and `tree_json` that any consumer reads, with file:line. Becomes phase 2's checklist.
- **Linked-ticket → code path map**: for each linked ticket: file(s), field(s), and resolving phase. Makes phase-3 ticket-cutting mechanical.

### Phase 2 (future ticket): drop the JSON blob

1. Add Blacklight-style stored display fields per the consumer map (`*_tesim` text/HTML, `*_ssim` facetable strings, `*_ssm` stored-only).
2. Rewrite `public/app/models/record.rb` and per-type subclasses to read named fields.
3. Remove `doc['json'] = …` at `indexer_common.rb:1280`; remove PUI re-merge re-store at `pui_indexer.rb:83-88`; drop `json`, `tree_json`, `whole_tree_json` from `solr/schema.xml`.
4. Reindex required on upgrade (allowed by ticket).

### Phase 3 (future tickets): bug-cluster fixes

Each maps to a linked ticket cluster with a direct Arclight precedent:

- **`extract_string_values` removal + `qf_default` paramset**: walker and the `fullrecord` / `fullrecord_published` synthetic fields are removed; default keyword search routes to a `qf_default` `<initParams>` paramset that enumerates source fields directly. Closes ANW-2657, ANW-201, ANW-1672.
- **Identifier search**: `identifier_match` field type + `qf_identifier` paramset enumerating identifier-bearing fields directly. Closes ANW-290, ANW-1556, ANW-2071, ANW-2075.
- **Punctuation handling**: `string_punct_stop` field type. Closes ANW-1686, ANW-308.
- **Non-Roman scripts**: `ICUTokenizerFactory` + `ICUFoldingFilterFactory`. Closes ANW-1178; helps ANW-859 (with `mm=4<90%`).
- **Highlighting**: derive `summary` from `notes_published`. Closes ANW-2315.
- **Per-search-type `qf` groups as `solrconfig.xml` paramsets**: `qf_default` / `qf_identifier` / `qf_title` / `qf_name` / `qf_subject` / `qf_place` / `qf_container` declared as `<initParams>` blocks; backend selects via `useParams=<name>` instead of building `qf` strings. Per-locale boosts are paramsets `qf_locale_<iso>_<script>` composed onto the request. Closes ANW-2656; addresses per-field PUI advanced-search bugs. Absorbs MCTF §5.5.5 per-locale `qf` boost.
- **Filter correctness**: `published_creators`, consistent `level` field. Closes ANW-262, ANW-1580, ANW-1102, ANW-862, ANW-1628.
- **Block-join hierarchy** (under evaluation): `_root_` / `_nest_parent_` / `_nest_path_` to drop `RecordInheritance.merge` and the ancestor-array denormalisation. Block-join's win is ancestor inheritance, not multilingual fan-out (which the unified MLC design already handles per MCTF §5.5.3). Largest change; do last.
- **Indexer reliability (ANW-902)**: separate investigation, unrelated to schema shape.

## Verification (Phase 1)

All new specs must pass against unchanged production code; they characterise existing behaviour.

- `./build/run backend:test -Dspec="model_solr_spec.rb"`.
- Indexer specs: invocation per `build/build.xml`; confirm CI target before adding new files.
- `./build/run public:test -Dspec="models/record_spec.rb"` (and per-type specs).
- `./build/run rubocop` clean.
- Manual sanity: bring up Solr + backend + indexer, index a fixture resource, dump one Solr doc with `curl 'http://localhost:8090/solr/archivesspace/select?q=*:*&rows=1&wt=json'`, spot-check field set matches new spec assertions.
- Inventory review: every Solr field has writer + reader columns; every blob top-level key has a reader file:line; every linked Jira ticket has a row.

## Proposed Jira ticket breakdown (draft)

**Epic structure.** ANW-2229 converted in place from Task → Epic (description, comments, attachments, ASRM-27 link preserved). Sub-tickets become children. Existing linked tickets stay in their current state and close individually as phase-3 children land.

**Sprint sizing.** Each sub-ticket scoped to fit in one 3-week sprint. 🟡 = tight; 🔴 = larger than one sprint, must be split before assignment.

### Phase 1 sub-tickets (3: can run in parallel)

**P1.1: Indexer characterization specs**
- Scope: `indexer/spec/indexer_common_spec.rb` covering all 17 record types. New direct spec for `extract_string_values`. `pui_indexer_spec.rb` for `RecordInheritance.merge` re-store. `large_tree_doc_indexer_spec.rb` real assertions on `tree_root` / `tree_waypoint` / `tree_node`. Plugin hook spec.
- Acceptance: all specs pass against unchanged code; rubocop clean.
- Closes: part of ANW-2229 spec deliverable.
- MLC: add fixture variants with `lang_descriptions` for the 5 MLC-using record types (resource, accession, archival_object, digital_object, digital_object_component); assert `mlc_fields` shape, `*_<iso>_mlc` per-language emission, and language-suffixed tree-doc fan-out as currently shipped in PR #4046 (see "MLC coordination" section).
- Sprint fit: 🟡 1 sprint (split into 1.1a core + 1.1b agents/auxiliary if squeezed).

**P1.2: Public Record + backend Solr query characterization specs**
- Scope: New `public/spec/models/record_spec.rb` + per-subclass specs for 9 PUI record types. Stub `solr_result` fixtures, assert `@json[...]` reads + accessor outputs. Extend `backend/spec/model_solr_spec.rb` for `qf`/`pf`/`defType`/`fq`/facet shape on keyword + advanced + match-all entry points.
- Acceptance: 9 PUI types covered; backend Solr specs lock current behaviour.
- Closes: part of ANW-2229 spec deliverable; locks the contract phase 2 must preserve.
- Sprint fit: 1 sprint.

**P1.3: Search-refactor inventory document**
- Scope: Commit `docs/search_refactor_inventory.md` with three tables (Solr field map, JSON-blob consumer map, linked-ticket → code-path map).
- Acceptance: every Solr field has writer + reader columns; every blob key has a reader file:line; every linked ticket has a row.
- Closes: phase 1 documentation deliverable.
- MLC: Solr field map enumerates `*_<iso>_mlc` dynamic fields and the 7 `text_<iso>` field types; JSON-blob consumer map includes `mlc_fields`; disposition column flags the post-rename target name `*_<iso>_<script>_tesim` (per MCTF §5.5.1).
- Sprint fit: 1 sprint.

### Phase 2 sub-tickets (3: sequential, depend on phase 1)

**P2.1: Add Blacklight-style stored display fields alongside JSON blob**
- Depends on: P1.2 + P1.3.
- Scope: New Solr fields per consumer map using `*_tesim` / `*_ssim` / `*_ssm` / `*_html_tesm` suffixes. Indexer writes both old blob and new fields. Parity spec per record type.
- Acceptance: parity spec passes; existing P1.x specs pass; reindex test on fixture dataset emits both representations.
- MLC: coordinate the multilingual field-name list with MCTF §5.6's schema-rename pass (`<field>_<iso>_<script>_tesim` plus `<field>_primary_tesim` companion). Either land MCTF's rename first and have P2.1 add only the non-multilingual fields, or land both in one PR; either way the post-state has one consistent suffix scheme.
- Sprint fit: 🟡 1 sprint.

**P2.2: Rewrite public Record + PUI controllers to read named fields**
- Depends on: P2.1.
- Scope: `public/app/models/record.rb` + per-type subclasses read named fields. PUI controllers + `archives_space_client.rb:115` migrated. JSON blob still emitted as fallback.
- Acceptance: P1.2 specs still pass (same accessor outputs); golden-path browser test (search → result list → drill-down) matches captured baseline.
- Sprint fit: 1 sprint.

**P2.3: Drop `json` / `tree_json` / `whole_tree_json` fields and indexer writes**
- Depends on: P2.2.
- Scope: Remove `doc['json'] = …` at `indexer_common.rb:1280`; remove PUI re-merge re-store at `pui_indexer.rb:83-88`; drop blob fields from `solr/schema.xml`; bump schema version. Release notes document required full reindex.
- Acceptance: index no longer carries blob fields; size reduction measured; PUI works on freshly reindexed fixture data.
- Closes: headline of ANW-2229.
- Sprint fit: 1 sprint.

### Phase 3 sub-tickets (6: mostly parallel after P2 ships)

**P3.1: Remove `extract_string_values`; route default search to a `qf_default` paramset**
- Depends on: P2.3, P3.4 (paramset infrastructure).
- Scope: remove `IndexerCommon.extract_string_values` (`indexer/app/lib/indexer_common.rb:140-207`) and `IndexerCommon.build_fullrecord` (`:210-214`); drop the `fullrecord` and `fullrecord_published` field declarations from `solr/schema.xml`. Default keyword search routes to a `qf_default` paramset (declared via `<initParams>` in `solrconfig.xml`) whose `qf` enumerates the source fields explicitly. Per-record-type / per-context paramsets reuse the same enumeration discipline. No catchall. Publish-status handling is rebuilt without the parallel-field workaround: the indexer continues to emit a `publish` flag and a per-component publish chain; PUI search applies an `fq` to scope to published content. The few cases where staff search needs to see unpublished sub-record content (e.g. an unpublished archival object's title in a published resource) are handled by per-field `_unpublished` variants emitted by the indexer for the relevant fields, scoped via paramset alongside their public counterparts.
- Acceptance: spec asserts subject URIs / internal IDs / container labels / agent contacts / event-record IDs do NOT match a default keyword search; manual reproduction of the three closed tickets fails; index size after reindex measurably smaller (catchall storage gone).
- Closes: ANW-2657, ANW-201, ANW-1672.
- MLC: per-language fields (`title_eng_Latn_tesim`, etc.) are entered into the search index by the indexer's `document_prepare_hook` (MCTF §5.5.2). They become searchable by appearing in `qf_default` (their primary-language counterpart) and in `qf_locale_<iso>_<script>` paramsets (where the locale-specific weight is set). No copyField glob; the source-field list across paramsets is the contract.
- Sprint fit: 🟡 1 sprint (publish-status rework adds scope; split into 3.1a walker removal + paramset routing and 3.1b publish-status mechanism if squeezed).

**P3.2: `identifier_match` field type + `qf_identifier` paramset**
- Depends on: P2.3, P3.4 (paramset infrastructure).
- Scope: new `identifier_match` field type in `solr/schema.xml` (WordDelimiterGraphFilter with `catenateWords=1 catenateNumbers=1 catenateAll=1`); the indexer emits identifier sub-parts into `identifier_match` for resources, archival objects, accessions, digital objects, and digital object components. New `qf_identifier` paramset (declared via `<initParams>` in `solrconfig.xml`) enumerates identifier-bearing fields directly with appropriate boosts: `id^4 ead_id^3 ref_id^3 component_id^3 digital_object_id^3 identifier_match^4 unitid_ssm^2`. No `identifier_search` catchall. `backend/app/model/solr.rb` routes identifier-context searches via `useParams=qf_identifier`.
- Acceptance: spec asserts multi-part IDs (e.g. `MS-2024-001` ↔ `MS2024001`) match in either catenation; advanced search "Identifier contains" passes for all flagged variants.
- Closes: ANW-290, ANW-1556, ANW-2071, ANW-2075.
- Sprint fit: 1 sprint.

**P3.3: ICU analyzer chain + punctuation stopwords + `mm`**
- Depends on: P3.4 (paramsets carry `mm`).
- Scope: introduce a new `text_icu` field type in `solr/schema.xml` based on `ICUTokenizerFactory` + `ICUFoldingFilterFactory`; redirect the `*_tesim` dynamic field declaration to use `text_icu` instead of `text_general`. Add a `string_punct_stop` field type for fields where `& : ; [ ]` should be treated as query-side stopwords (apply selectively). Set `mm=4<90%` on every paramset that drives a default-style keyword search (`qf_default`, `qf_title`, `qf_name`, etc.) so short queries require all terms and long queries require 90%.
- Acceptance: spec coverage for ASCII-folded + ICU-folded + non-Roman searches (Cyrillic, Arabic, Hebrew, Greek, CJK); punctuation queries no longer 500 or silently drop; `mm=4<90%` confirmed on every keyword-style paramset.
- Closes: ANW-1178, ANW-1686, ANW-308, ANW-859.
- MLC: preserve the 7 `text_<iso>` `<fieldType>` definitions and the `solr/lang/` stopword / contraction / stemdict files from MLC PR #4046 unchanged. They apply to per-language `*_<iso>_<script>_tesim` fields, independent of the new `text_icu` type backing the generic `*_tesim` suffix. Records in non-curated languages fall through to `text_icu` and benefit from ICU folding without language-specific stemming.
- Sprint fit: 1 sprint.

**P3.4: Per-search-type `qf` groups (linker typeaheads + advanced search)**
- Depends on: P2.3.
- Scope: relevance configuration moves from Ruby string-building (`backend/app/model/solr.rb:345-350`) into Solr server-side **named parameter sets** (`<initParams>`) declared in `solrconfig.xml`. **No catchall**: each paramset's `qf` enumerates its source fields directly, and fields not enumerated in any paramset are not searchable by default. Define paramsets `qf_default` / `qf_identifier` / `qf_title` / `qf_name` / `qf_subject` / `qf_place` / `qf_container`, each carrying its own `qf` / `pf` / `mm` / `tie` configuration. `qf_default` lists the cross-record-type defaults (titles, identifiers, repository, dates, agents, subjects, primary-language note text); per-context paramsets specialise. Backend per-request work shrinks to selecting which paramset(s) apply via `useParams=<name>[,<name>...]`; no per-request `qf`/`pf` strings are sent. `backend/app/model/solr.rb` is rewritten to emit `useParams` based on search context (default keyword / identifier / linker type / advanced-search field). `frontend/app/views/{resources,agents,subjects,…}/_linker.html.erb` and `linker.js` propagate the linker type so the backend picks the right paramset. Arclight's `solrconfig.xml` is the direct precedent. **Foundation for P3.1, P3.2, P3.3**: those tickets all add to or modify the paramset enumeration.
- Acceptance: agent linker prioritises name hits; subject linker prioritises term hits; resource linker prioritises title + identifier; relevance changes ship by editing `solrconfig.xml` and reloading the core, no Ruby redeploy required; Solr response `params` echo confirms the merged paramset for each request.
- Closes: ANW-2656.
- MLC: per-locale boosts are additional paramsets named `qf_locale_<iso>_<script>` (e.g. `qf_locale_fre_Latn`) carrying the locale-specific field weights (`title_fre_Latn_tesim^3`, `finding_aid_title_fre_Latn_tesim^2`). The backend appends the locale paramset to the active list when the request carries an active locale that matches one of the seven curated languages. `useParams=qf_default,qf_locale_fre_Latn` is the composed form. This absorbs the MCTF §5.5.5 per-locale `qf` boost work; the corresponding bullet is removed from MCTF §5.6.
- Touches: `solr/solrconfig.xml` (paramset declarations), `backend/app/model/solr.rb` (paramset selection logic), `backend/spec/model_solr_spec.rb` (P1.2 spec assertions update from per-request `qf` strings to per-request `useParams` selections), `frontend/app/views/.../linker.html.erb` + `linker.js` (linker-type propagation).
- Sprint fit: 🟡 1 sprint (split into 3.4a `solrconfig.xml` paramsets + backend selection + 3.4b linker propagation if needed).

**P3.5: Highlighting + `summary` derived from `notes_published`**
- Depends on: P2.3.
- Scope: `indexer_common.rb` derives `summary` from same analyzer output as `notes_published`. Solr highlighting configured against the actual matching note field rather than a synthetic catchall. The PUI displays highlighted snippets per source field, attributing each match to the field that hit (notes vs. abstract vs. scope content). Possible because the catchall is gone (P3.1): every match is already attributable to a real source field.
- Acceptance: search hit with match in any note field renders a highlighted snippet showing the matched word in context, with field attribution where useful.
- Closes: ANW-2315.
- Sprint fit: 1 sprint.

**P3.6: Filter correctness: published creators + consistent level field**
- Depends on: P2.3.
- Scope: Indexer adds `published_creators`. `level` collapses its three writers (`indexer_common.rb:306, 529, 549`) into a single source of truth with consistent `otherlevel → other_level` substitution. Backend routes Creator + Level facet filters to the new fields.
- Acceptance: PUI Creator filter excludes records whose only matching creator is unpublished; level facet matches displayed level.
- Closes: ANW-262, ANW-1580.
- Sprint fit: 1 sprint.

### Parking lot

- 🔴 **X.1: Block-join hierarchy migration.** `_root_` / `_nest_parent_` / `_nest_path_` to drop `RecordInheritance.merge` and the ancestor-array denormalisation on every component doc, with optional knock-on simplification of `large_tree_doc_indexer`'s waypoint hack. Block-join's primary win is **ancestor inheritance**, not the multilingual collapse: the per-language tree-doc fan-out is already handled by the unified MLC design (per-language fields per node, see MCTF §5.5.3) without block-join. Multi-sprint; needs spike + design doc; reframe as its own Epic.
- **X.2: ANW-902** (PUI indexer occasionally drops AOs from new EADs). Separate investigation; likely race / transaction-boundary bug.
- **X.3: Minor PUI tickets to re-evaluate after phase 3**: ANW-1102, ANW-862, ANW-1628. Reassess against new schema before scoping.

### Pending Jira admin actions (run after plan approval, before sub-tickets are created)

1. ~~**Convert ANW-2229 from Task → Epic.**~~ ✅ Done.
2. ~~**Apply cluster-prefix titles** to all four linked-ticket clusters.~~ ✅ Done. 16 tickets renamed (ANW-2657, ANW-1672, ANW-201; ANW-290, ANW-1556, ANW-2071, ANW-2075; ANW-308, ANW-1686, ANW-859, ANW-1178; ANW-262, ANW-1580, ANW-1102, ANW-862, ANW-1628).
3. **Create the 12 sub-tickets** from the breakdown above with `Epic Link = ANW-2229`.
